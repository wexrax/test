class SavingsAlternativeCatalogEntry {
  const SavingsAlternativeCatalogEntry({
    required this.serviceAliases,
    required this.categoryAliases,
    required this.alternativeName,
    required this.monthlyPrice,
    required this.url,
  });

  final List<String> serviceAliases;
  final List<String> categoryAliases;
  final String alternativeName;
  final double monthlyPrice;
  final String url;

  bool matches({required String serviceName, required String category}) {
    final normalizedService = normalizeCatalogText(serviceName);
    final normalizedCategory = normalizeCatalogText(category);
    return serviceAliases.any(
          (alias) => normalizedService.contains(normalizeCatalogText(alias)),
        ) ||
        categoryAliases.any(
          (alias) => normalizedCategory == normalizeCatalogText(alias),
        );
  }
}

String normalizeCatalogText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]+'), '');
}

const savingsAlternativeCatalog = [
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['netflix', 'okko', 'ivi', 'кинопоиск', 'wink'],
    categoryAliases: ['видео', 'video'],
    alternativeName: 'Кинопоиск',
    monthlyPrice: 399,
    url: 'https://hd.kinopoisk.ru/',
  ),
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['youtube premium', 'youtube'],
    categoryAliases: ['видео', 'video'],
    alternativeName: 'VK Видео',
    monthlyPrice: 0,
    url: 'https://vk.com/video',
  ),
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['spotify', 'apple music', 'сберзвук'],
    categoryAliases: ['музыка', 'music'],
    alternativeName: 'VK Музыка',
    monthlyPrice: 149,
    url: 'https://music.vk.com/',
  ),
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['яндекс музыка'],
    categoryAliases: ['музыка', 'music'],
    alternativeName: 'VK Музыка',
    monthlyPrice: 149,
    url: 'https://music.vk.com/',
  ),
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['dropbox', 'google one', 'icloud', 'icloud+'],
    categoryAliases: ['облако', 'cloud'],
    alternativeName: 'Облако Mail.ru',
    monthlyPrice: 99,
    url: 'https://cloud.mail.ru/',
  ),
  SavingsAlternativeCatalogEntry(
    serviceAliases: ['notion'],
    categoryAliases: [],
    alternativeName: 'Anytype',
    monthlyPrice: 0,
    url: 'https://anytype.io/',
  ),
];
