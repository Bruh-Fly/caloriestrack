import 'package:flutter/widgets.dart';

extension AppText on BuildContext {
  String tr(String english, String vietnamese) {
    final code = Localizations.localeOf(this).languageCode;
    if (code == 'vi') return vietnamese;
    if (code == 'en') return english;
    return _translations[english]?[code] ?? english;
  }
}

const _translations = <String, Map<String, String>>{
  'Today': {
    'es': 'Hoy',
    'fr': "Aujourd’hui",
    'zh': '今天',
    'hi': 'आज',
    'ar': 'اليوم'
  },
  'Summary': {
    'es': 'Resumen',
    'fr': 'Résumé',
    'zh': '总结',
    'hi': 'सारांश',
    'ar': 'الملخص'
  },
  'Details': {
    'es': 'Detalles',
    'fr': 'Détails',
    'zh': '详情',
    'hi': 'विवरण',
    'ar': 'التفاصيل'
  },
  'Eaten': {
    'es': 'Consumido',
    'fr': 'Consommé',
    'zh': '已摄入',
    'hi': 'खाया',
    'ar': 'المتناول'
  },
  'Remaining': {
    'es': 'Restante',
    'fr': 'Restant',
    'zh': '剩余',
    'hi': 'शेष',
    'ar': 'المتبقي'
  },
  'Burned': {
    'es': 'Quemado',
    'fr': 'Brûlé',
    'zh': '已消耗',
    'hi': 'जली कैलोरी',
    'ar': 'المحروق'
  },
  'Nutrition': {
    'es': 'Nutrición',
    'fr': 'Nutrition',
    'zh': '营养',
    'hi': 'पोषण',
    'ar': 'التغذية'
  },
  'More': {'es': 'Más', 'fr': 'Plus', 'zh': '更多', 'hi': 'और', 'ar': 'المزيد'},
  'Breakfast': {
    'es': 'Desayuno',
    'fr': 'Petit-déjeuner',
    'zh': '早餐',
    'hi': 'नाश्ता',
    'ar': 'الإفطار'
  },
  'Lunch': {
    'es': 'Almuerzo',
    'fr': 'Déjeuner',
    'zh': '午餐',
    'hi': 'दोपहर का भोजन',
    'ar': 'الغداء'
  },
  'Dinner': {
    'es': 'Cena',
    'fr': 'Dîner',
    'zh': '晚餐',
    'hi': 'रात का खाना',
    'ar': 'العشاء'
  },
  'Snacks': {
    'es': 'Tentempiés',
    'fr': 'Collations',
    'zh': '零食',
    'hi': 'नाश्ता',
    'ar': 'وجبات خفيفة'
  },
  'Fasting': {
    'es': 'Ayuno',
    'fr': 'Jeûne',
    'zh': '禁食',
    'hi': 'उपवास',
    'ar': 'الصيام'
  },
  'Go to Fasting': {
    'es': 'Ir al ayuno',
    'fr': 'Ouvrir le jeûne',
    'zh': '进入禁食',
    'hi': 'उपवास खोलें',
    'ar': 'ابدأ الصيام'
  },
  'Water': {'es': 'Agua', 'fr': 'Eau', 'zh': '饮水', 'hi': 'पानी', 'ar': 'الماء'},
  'Activities': {
    'es': 'Actividades',
    'fr': 'Activités',
    'zh': '活动',
    'hi': 'गतिविधियाँ',
    'ar': 'الأنشطة'
  },
  'Search': {
    'es': 'Buscar',
    'fr': 'Rechercher',
    'zh': '搜索',
    'hi': 'खोजें',
    'ar': 'بحث'
  },
  'Camera': {
    'es': 'Cámara',
    'fr': 'Caméra',
    'zh': '相机',
    'hi': 'कैमरा',
    'ar': 'الكاميرا'
  },
  'Barcode': {
    'es': 'Código de barras',
    'fr': 'Code-barres',
    'zh': '条形码',
    'hi': 'बारकोड',
    'ar': 'الباركود'
  },
  'Voice/Text': {
    'es': 'Voz/Texto',
    'fr': 'Voix/Texte',
    'zh': '语音/文字',
    'hi': 'आवाज़/पाठ',
    'ar': 'صوت/نص'
  },
  'Search food online': {
    'es': 'Buscar alimentos en línea',
    'fr': 'Rechercher des aliments',
    'zh': '在线搜索食物',
    'hi': 'खाना ऑनलाइन खोजें',
    'ar': 'ابحث عن الطعام'
  },
  'Settings': {
    'es': 'Ajustes',
    'fr': 'Paramètres',
    'zh': '设置',
    'hi': 'सेटिंग्स',
    'ar': 'الإعدادات'
  },
  'Preferences': {
    'es': 'Preferencias',
    'fr': 'Préférences',
    'zh': '偏好设置',
    'hi': 'प्राथमिकताएँ',
    'ar': 'التفضيلات'
  },
  'Language': {
    'es': 'Idioma',
    'fr': 'Langue',
    'zh': '语言',
    'hi': 'भाषा',
    'ar': 'اللغة'
  },
  'Active': {
    'es': 'Activo',
    'fr': 'Actif',
    'zh': '活跃',
    'hi': 'सक्रिय',
    'ar': 'نشط'
  },
  'Green Days': {
    'es': 'Días verdes',
    'fr': 'Jours verts',
    'zh': '达标日',
    'hi': 'ग्रीन दिन',
    'ar': 'أيام الالتزام'
  },
  'Weight': {
    'es': 'Peso',
    'fr': 'Poids',
    'zh': '体重',
    'hi': 'वज़न',
    'ar': 'الوزن'
  },
  'Share Your Success': {
    'es': 'Comparte tu progreso',
    'fr': 'Partagez vos progrès',
    'zh': '分享你的进步',
    'hi': 'अपनी प्रगति साझा करें',
    'ar': 'شارك إنجازك'
  },
  'View day details': {
    'es': 'Ver detalles del día',
    'fr': 'Voir les détails du jour',
    'zh': '查看每日详情',
    'hi': 'दिन का विवरण देखें',
    'ar': 'عرض تفاصيل اليوم'
  },
  'Diary': {
    'es': 'Diario',
    'fr': 'Journal',
    'zh': '日记',
    'hi': 'डायरी',
    'ar': 'يومياتي'
  },
  'Recipes': {
    'es': 'Recetas',
    'fr': 'Recettes',
    'zh': '食谱',
    'hi': 'रेसिपी',
    'ar': 'الوصفات'
  },
  'Profile': {
    'es': 'Perfil',
    'fr': 'Profil',
    'zh': '个人资料',
    'hi': 'प्रोफ़ाइल',
    'ar': 'الملف الشخصي'
  },
  'Pro': {'es': 'Pro', 'fr': 'Pro', 'zh': '专业版', 'hi': 'प्रो', 'ar': 'برو'},
  'Calories': {
    'es': 'Calorías',
    'fr': 'Calories',
    'zh': '卡路里',
    'hi': 'कैलोरी',
    'ar': 'السعرات'
  },
  'Carbs': {
    'es': 'Carbohidratos',
    'fr': 'Glucides',
    'zh': '碳水',
    'hi': 'कार्ब्स',
    'ar': 'الكربوهيدرات'
  },
  'Protein': {
    'es': 'Proteína',
    'fr': 'Protéines',
    'zh': '蛋白质',
    'hi': 'प्रोटीन',
    'ar': 'البروتين'
  },
  'Fat': {
    'es': 'Grasa',
    'fr': 'Lipides',
    'zh': '脂肪',
    'hi': 'वसा',
    'ar': 'الدهون'
  },
  'Goal': {
    'es': 'Objetivo',
    'fr': 'Objectif',
    'zh': '目标',
    'hi': 'लक्ष्य',
    'ar': 'الهدف'
  },
  'Meals': {
    'es': 'Comidas',
    'fr': 'Repas',
    'zh': '餐食',
    'hi': 'भोजन',
    'ar': 'الوجبات'
  },
  'Nutrition facts': {
    'es': 'Datos nutricionales',
    'fr': 'Valeurs nutritionnelles',
    'zh': '营养信息',
    'hi': 'पोषण तथ्य',
    'ar': 'حقائق التغذية'
  },
  'Track now': {
    'es': 'Registrar ahora',
    'fr': 'Suivre maintenant',
    'zh': '立即记录',
    'hi': 'अभी ट्रैक करें',
    'ar': 'سجّل الآن'
  },
  'Add more': {
    'es': 'Añadir más',
    'fr': 'Ajouter plus',
    'zh': '继续添加',
    'hi': 'और जोड़ें',
    'ar': 'أضف المزيد'
  },
};
