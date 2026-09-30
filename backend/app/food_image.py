from io import BytesIO

from fastapi import HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.config import get_settings

_ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP"}
_MAX_DIMENSION = 1600


async def normalize_food_image(upload: UploadFile) -> bytes:
    raw = await upload.read(get_settings().max_upload_bytes + 1)
    if not raw or len(raw) > get_settings().max_upload_bytes:
        raise HTTPException(status_code=413, detail="Image exceeds the upload size limit")

    try:
        with Image.open(BytesIO(raw)) as source:
            # Verify the file contents rather than trusting the multipart MIME
            # label: Android gallery providers sometimes report a generic or
            # incorrect content type for otherwise valid JPEG/PNG/WebP files.
            if source.format not in _ALLOWED_FORMATS:
                raise HTTPException(
                    status_code=415,
                    detail="Upload a JPEG, PNG, or WebP food photo",
                )
            if source.width * source.height > 25_000_000:
                raise HTTPException(status_code=413, detail="Image pixel dimensions are too large")
            image = ImageOps.exif_transpose(source).convert("RGB")
            image.thumbnail((_MAX_DIMENSION, _MAX_DIMENSION))
            output = BytesIO()
            image.save(output, format="JPEG", quality=88, optimize=True)
            return output.getvalue()
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError) as exc:
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image") from exc
