import 'dart:ui';

class ChangeLogStrings {
  final List<ChangeLogEntryStrings> entries;

  const ChangeLogStrings({required this.entries});

  static ChangeLogStrings? maybeForLocale(
    Locale locale, {
    bool isLocalGallery = false,
    required bool isAndroid,
  }) {
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final strings =
        _translations[key] ??
        _translations[locale.languageCode] ??
        _translations['en'];

    if (strings == null) {
      return null;
    }

    return strings.forAudience(
      isLocalGallery: isLocalGallery,
      isAndroid: isAndroid,
    );
  }

  ChangeLogStrings? forAudience({
    bool isLocalGallery = false,
    required bool isAndroid,
  }) {
    final visibleEntries = entries
        .where((entry) => !entry.isAndroidOnly || isAndroid)
        .where((entry) => !entry.isIOSOnly || !isAndroid)
        .where(
          (entry) =>
              isLocalGallery ? !entry.isOnlineOnly : !entry.isLocalGalleryOnly,
        )
        .toList(growable: false);
    return visibleEntries.isEmpty
        ? null
        : ChangeLogStrings(entries: visibleEntries);
  }

  static bool hasContentForLocale(
    Locale locale, {
    bool isLocalGallery = false,
    required bool isAndroid,
  }) {
    return maybeForLocale(
          locale,
          isLocalGallery: isLocalGallery,
          isAndroid: isAndroid,
        ) !=
        null;
  }

  static const Map<String, ChangeLogStrings> _translations = {
    'en': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Preview strip in the viewer',
          description:
              'Thumbnails at the bottom of the viewer let you jump between photos and videos faster.',
        ),
        ChangeLogEntryStrings(
          title: 'Share photos of a person',
          description:
              'Share photos of a person with a link that can automatically include new photos of them.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Set photos as wallpaper',
          description: 'Set a photo as your home screen, lock screen, or both.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Hold for 2× playback',
          description: 'Press and hold a video to watch it at 2× speed.',
        ),
        ChangeLogEntryStrings(
          title: 'And more!',
          description:
              'More efficient gallery scrolling and back buttons that are easier to tap.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'And more!',
          description:
              'More efficient gallery scrolling, back buttons that are easier to tap, and improved backups.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'And more!',
          description:
              'More efficient gallery scrolling and back buttons that are easier to tap.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'ca': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Franja de previsualitzacions al visor',
          description:
              'Les miniatures de la part inferior del visor et permeten saltar més ràpidament entre fotos i vídeos.',
        ),
        ChangeLogEntryStrings(
          title: 'Comparteix les fotos d’una persona',
          description:
              'Comparteix les fotos d’una persona amb un enllaç que pot incloure automàticament fotos noves seves.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Estableix fotos com a fons de pantalla',
          description:
              'Estableix una foto com a fons de la pantalla d’inici, de bloqueig o de totes dues.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Mantén premut per reproduir a 2×',
          description: 'Mantén premut un vídeo per veure’l a velocitat 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'I més coses!',
          description:
              'Desplaçament més eficient per la galeria i botons Enrere més fàcils de tocar.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'I més coses!',
          description:
              'Desplaçament més eficient per la galeria, botons Enrere més fàcils de tocar i còpies de seguretat millorades.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'I més coses!',
          description:
              'Desplaçament més eficient per la galeria i botons Enrere més fàcils de tocar.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'cs': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Pás náhledů v prohlížeči',
          description:
              'Miniatury ve spodní části prohlížeče umožňují rychleji přecházet mezi fotografiemi a videi.',
        ),
        ChangeLogEntryStrings(
          title: 'Sdílení fotografií osoby',
          description:
              'Sdílejte fotografie osoby pomocí odkazu, který může automaticky zahrnovat její nové fotografie.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Nastavení fotografií jako tapety',
          description:
              'Nastavte fotografii jako tapetu domovské obrazovky, zamykací obrazovky nebo obou.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Podržením přehrajete 2× rychleji',
          description:
              'Stisknutím a podržením videa ho můžete sledovat 2× rychleji.',
        ),
        ChangeLogEntryStrings(
          title: 'A mnohem více!',
          description:
              'Efektivnější posouvání v galerii a tlačítka Zpět, na která se snáze klepá.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'A mnohem více!',
          description:
              'Efektivnější posouvání v galerii, tlačítka Zpět, na která se snáze klepá, a vylepšené zálohování.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'A mnohem více!',
          description:
              'Efektivnější posouvání v galerii a tlačítka Zpět, na která se snáze klepá.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'de': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Vorschauleiste in der Fotoansicht',
          description:
              'Über die Miniaturansichten am unteren Rand kannst du schneller zwischen Fotos und Videos wechseln.',
        ),
        ChangeLogEntryStrings(
          title: 'Fotos einer Person teilen',
          description:
              'Teile die Fotos einer Person über einen Link, der neue Fotos von ihr automatisch aufnehmen kann.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Fotos als Hintergrund festlegen',
          description:
              'Lege ein Foto als Hintergrund für den Startbildschirm, den Sperrbildschirm oder beide fest.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Für 2× Wiedergabe gedrückt halten',
          description:
              'Halte ein Video gedrückt, um es mit 2× Geschwindigkeit anzusehen.',
        ),
        ChangeLogEntryStrings(
          title: 'Und mehr!',
          description:
              'Effizienteres Scrollen in der Galerie und Zurück-Schaltflächen, die sich leichter antippen lassen.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Und mehr!',
          description:
              'Effizienteres Scrollen in der Galerie, Zurück-Schaltflächen, die sich leichter antippen lassen, und verbesserte Datensicherungen.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Und mehr!',
          description:
              'Effizienteres Scrollen in der Galerie und Zurück-Schaltflächen, die sich leichter antippen lassen.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'es': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Tira de vistas previas en el visor',
          description:
              'Las miniaturas de la parte inferior del visor te permiten saltar más rápido entre fotos y vídeos.',
        ),
        ChangeLogEntryStrings(
          title: 'Compartir fotos de una persona',
          description:
              'Comparte las fotos de una persona con un enlace que puede incluir automáticamente nuevas fotos suyas.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Usar fotos como fondo de pantalla',
          description:
              'Establece una foto como fondo de la pantalla de inicio, de la pantalla de bloqueo o de ambas.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Mantén pulsado para reproducir a 2×',
          description:
              'Mantén pulsado un vídeo para verlo a una velocidad de 2×.',
        ),
        ChangeLogEntryStrings(
          title: '¡Y mucho más!',
          description:
              'Desplazamiento más eficiente por la galería y botones Atrás más fáciles de tocar.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '¡Y mucho más!',
          description:
              'Desplazamiento más eficiente por la galería, botones Atrás más fáciles de tocar y copias de seguridad mejoradas.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '¡Y mucho más!',
          description:
              'Desplazamiento más eficiente por la galería y botones Atrás más fáciles de tocar.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'fr': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Bandeau d’aperçus dans la visionneuse',
          description:
              'Les vignettes au bas de la visionneuse vous permettent de passer plus rapidement d’une photo ou vidéo à l’autre.',
        ),
        ChangeLogEntryStrings(
          title: 'Partager les photos d’une personne',
          description:
              'Partagez les photos d’une personne avec un lien qui peut inclure automatiquement ses nouvelles photos.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Définir des photos comme fond d’écran',
          description:
              'Définissez une photo comme fond de l’écran d’accueil, de l’écran de verrouillage ou des deux.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Maintenir pour lire à 2×',
          description:
              'Appuyez longuement sur une vidéo pour la regarder à vitesse 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'Et plus encore !',
          description:
              'Défilement plus efficace dans la galerie et boutons de retour plus faciles à toucher.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Et plus encore !',
          description:
              'Défilement plus efficace dans la galerie, boutons de retour plus faciles à toucher et sauvegardes améliorées.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Et plus encore !',
          description:
              'Défilement plus efficace dans la galerie et boutons de retour plus faciles à toucher.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'it': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Striscia di anteprime nel visualizzatore',
          description:
              'Le miniature nella parte inferiore del visualizzatore ti consentono di passare più velocemente da una foto o un video all’altro.',
        ),
        ChangeLogEntryStrings(
          title: 'Condividi le foto di una persona',
          description:
              'Condividi le foto di una persona con un link che può includere automaticamente le sue nuove foto.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Imposta foto come sfondo',
          description:
              'Imposta una foto come sfondo della schermata Home, della schermata di blocco o di entrambe.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Tieni premuto per la riproduzione a 2×',
          description: 'Tieni premuto un video per guardarlo a velocità 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'E non è tutto!',
          description:
              'Scorrimento più efficiente della galleria e pulsanti Indietro più facili da toccare.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E non è tutto!',
          description:
              'Scorrimento più efficiente della galleria, pulsanti Indietro più facili da toccare e backup migliorati.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E non è tutto!',
          description:
              'Scorrimento più efficiente della galleria e pulsanti Indietro più facili da toccare.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'ja': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'ビューアーのプレビューストリップ',
          description: 'ビューアー下部のサムネイルから、写真やビデオへすばやく移動できます。',
        ),
        ChangeLogEntryStrings(
          title: '人物の写真を共有',
          description: '人物の写真をリンクで共有できます。リンクにはその人物の新しい写真を自動で追加できます。',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '写真を壁紙に設定',
          description: '写真をホーム画面、ロック画面、またはその両方の壁紙に設定できます。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '長押しで2×再生',
          description: 'ビデオを長押しすると、2×の速度で再生できます。',
        ),
        ChangeLogEntryStrings(
          title: 'ほかにも！',
          description: 'ギャラリーのスクロール効率が向上し、「戻る」ボタンがタップしやすくなりました。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'ほかにも！',
          description: 'ギャラリーのスクロール効率が向上し、「戻る」ボタンがタップしやすくなり、バックアップも改善しました。',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'ほかにも！',
          description: 'ギャラリーのスクロール効率が向上し、「戻る」ボタンがタップしやすくなりました。',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'nl': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Voorbeeldstrook in de viewer',
          description:
              "Miniaturen onderaan de viewer laten je sneller tussen foto's en video's springen.",
        ),
        ChangeLogEntryStrings(
          title: "Foto's van een persoon delen",
          description:
              "Deel foto's van een persoon via een link die automatisch nieuwe foto's van die persoon kan bevatten.",
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: "Foto's als achtergrond instellen",
          description:
              'Stel een foto in als achtergrond van je startscherm, vergrendelscherm of beide.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Vasthouden voor afspelen op 2×',
          description:
              'Houd een video ingedrukt om deze op 2× snelheid te bekijken.',
        ),
        ChangeLogEntryStrings(
          title: 'En meer!',
          description:
              'Efficiënter scrollen door de galerij en terugknoppen die makkelijker zijn aan te tikken.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'En meer!',
          description:
              'Efficiënter scrollen door de galerij, terugknoppen die makkelijker zijn aan te tikken en verbeterde back-ups.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'En meer!',
          description:
              'Efficiënter scrollen door de galerij en terugknoppen die makkelijker zijn aan te tikken.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'no': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Forhåndsvisningsstripe i visningen',
          description:
              'Miniatyrbilder nederst i visningen gjør at du kan hoppe raskere mellom bilder og videoer.',
        ),
        ChangeLogEntryStrings(
          title: 'Del bilder av en person',
          description:
              'Del bilder av en person med en lenke som automatisk kan ta med nye bilder av personen.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Bruk bilder som bakgrunn',
          description:
              'Bruk et bilde som bakgrunn på startskjermen, låseskjermen eller begge.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Hold inne for 2× avspilling',
          description: 'Trykk og hold på en video for å se den i 2× hastighet.',
        ),
        ChangeLogEntryStrings(
          title: 'Og mer!',
          description:
              'Mer effektiv rulling i galleriet og tilbakeknapper som er enklere å trykke på.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Og mer!',
          description:
              'Mer effektiv rulling i galleriet, tilbakeknapper som er enklere å trykke på og bedre sikkerhetskopiering.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Og mer!',
          description:
              'Mer effektiv rulling i galleriet og tilbakeknapper som er enklere å trykke på.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'pl': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Pasek podglądu w przeglądarce',
          description:
              'Miniatury u dołu przeglądarki pozwalają szybciej przechodzić między zdjęciami i filmami.',
        ),
        ChangeLogEntryStrings(
          title: 'Udostępnianie zdjęć osoby',
          description:
              'Udostępniaj zdjęcia osoby za pomocą linku, który może automatycznie uwzględniać jej nowe zdjęcia.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Ustawianie zdjęć jako tapety',
          description:
              'Ustaw zdjęcie jako tapetę ekranu głównego, ekranu blokady lub obu.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Przytrzymaj, aby odtwarzać 2× szybciej',
          description:
              'Naciśnij i przytrzymaj film, aby oglądać go 2× szybciej.',
        ),
        ChangeLogEntryStrings(
          title: 'I jeszcze więcej!',
          description:
              'Wydajniejsze przewijanie galerii i łatwiejsze do naciśnięcia przyciski Wstecz.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'I jeszcze więcej!',
          description:
              'Wydajniejsze przewijanie galerii, łatwiejsze do naciśnięcia przyciski Wstecz i ulepszone tworzenie kopii zapasowych.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'I jeszcze więcej!',
          description:
              'Wydajniejsze przewijanie galerii i łatwiejsze do naciśnięcia przyciski Wstecz.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'pt_BR': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Faixa de prévias no visualizador',
          description:
              'As miniaturas na parte inferior do visualizador permitem alternar mais rapidamente entre fotos e vídeos.',
        ),
        ChangeLogEntryStrings(
          title: 'Compartilhe fotos de uma pessoa',
          description:
              'Compartilhe fotos de uma pessoa com um link que pode incluir automaticamente novas fotos dela.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Defina fotos como papel de parede',
          description:
              'Defina uma foto como papel de parede da tela inicial, da tela de bloqueio ou de ambas.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Segure para reproduzir em 2×',
          description:
              'Mantenha um vídeo pressionado para assisti-lo em velocidade 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Rolagem mais eficiente na galeria e botões Voltar mais fáceis de tocar.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Rolagem mais eficiente na galeria, botões Voltar mais fáceis de tocar e backups aprimorados.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Rolagem mais eficiente na galeria e botões Voltar mais fáceis de tocar.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'pt_PT': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Faixa de pré-visualizações no visualizador',
          description:
              'As miniaturas na parte inferior do visualizador permitem alternar mais rapidamente entre fotografias e vídeos.',
        ),
        ChangeLogEntryStrings(
          title: 'Partilhar fotografias de uma pessoa',
          description:
              'Partilhe fotografias de uma pessoa através de uma ligação que pode incluir automaticamente novas fotografias dessa pessoa.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Definir fotografias como fundo',
          description:
              'Defina uma fotografia como fundo do ecrã principal, do ecrã de bloqueio ou de ambos.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Manter premido para reproduzir a 2×',
          description: 'Mantenha um vídeo premido para o ver à velocidade 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Deslocamento mais eficiente na galeria e botões Voltar mais fáceis de tocar.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Deslocamento mais eficiente na galeria, botões Voltar mais fáceis de tocar e cópias de segurança melhoradas.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'E muito mais!',
          description:
              'Deslocamento mais eficiente na galeria e botões Voltar mais fáceis de tocar.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'ro': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Bandă de previzualizare în vizualizator',
          description:
              'Miniaturile din partea de jos a vizualizatorului te ajută să treci mai repede între fotografii și videoclipuri.',
        ),
        ChangeLogEntryStrings(
          title: 'Partajează fotografiile unei persoane',
          description:
              'Partajează fotografiile unei persoane cu un link care poate include automat fotografii noi cu aceasta.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Setează fotografii ca fundal',
          description:
              'Setează o fotografie ca fundal pentru ecranul principal, ecranul de blocare sau ambele.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Ține apăsat pentru redare la 2×',
          description:
              'Ține apăsat pe un videoclip pentru a-l viziona la viteza 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'Și altele!',
          description:
              'Derulare mai eficientă în galerie și butoane Înapoi mai ușor de atins.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Și altele!',
          description:
              'Derulare mai eficientă în galerie, butoane Înapoi mai ușor de atins și copii de rezervă îmbunătățite.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Și altele!',
          description:
              'Derulare mai eficientă în galerie și butoane Înapoi mai ușor de atins.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'ru': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Лента превью в режиме просмотра',
          description:
              'Миниатюры в нижней части экрана просмотра позволяют быстрее переходить между фото и видео.',
        ),
        ChangeLogEntryStrings(
          title: 'Делитесь фотографиями человека',
          description:
              'Делитесь фотографиями человека по ссылке, в которую могут автоматически добавляться его новые фотографии.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Устанавливайте фото как обои',
          description:
              'Установите фотографию на главный экран, экран блокировки или на оба экрана.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Удерживайте для воспроизведения 2×',
          description:
              'Нажмите и удерживайте видео, чтобы смотреть его со скоростью 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'И многое другое!',
          description:
              'Более эффективная прокрутка галереи и кнопки «Назад», на которые проще нажимать.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'И многое другое!',
          description:
              'Более эффективная прокрутка галереи, кнопки «Назад», на которые проще нажимать, и улучшенное резервное копирование.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'И многое другое!',
          description:
              'Более эффективная прокрутка галереи и кнопки «Назад», на которые проще нажимать.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'tr': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Fotoğraf görüntüleyicide önizleme şeridi',
          description:
              'Görüntüleyicinin altındaki küçük resimler, fotoğraflar ve videolar arasında daha hızlı geçiş yapmanızı sağlar.',
        ),
        ChangeLogEntryStrings(
          title: 'Bir kişinin fotoğraflarını paylaşın',
          description:
              'Bir kişinin fotoğraflarını, o kişinin yeni fotoğraflarını otomatik olarak ekleyebilen bir bağlantıyla paylaşın.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Fotoğrafları duvar kâğıdı yapın',
          description:
              'Bir fotoğrafı ana ekranınızın, kilit ekranınızın veya her ikisinin duvar kâğıdı olarak ayarlayın.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '2× oynatma için basılı tutun',
          description:
              'Bir videoyu 2× hızda izlemek için videoya basılı tutun.',
        ),
        ChangeLogEntryStrings(
          title: 'Ve daha fazlası!',
          description:
              'Galeride daha verimli kaydırma ve daha kolay dokunulan Geri düğmeleri.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Ve daha fazlası!',
          description:
              'Galeride daha verimli kaydırma, daha kolay dokunulan Geri düğmeleri ve iyileştirilmiş yedeklemeler.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Ve daha fazlası!',
          description:
              'Galeride daha verimli kaydırma ve daha kolay dokunulan Geri düğmeleri.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'uk': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Стрічка попереднього перегляду у вікні перегляду',
          description:
              'Мініатюри внизу вікна перегляду дають змогу швидше переходити між фото й відео.',
        ),
        ChangeLogEntryStrings(
          title: 'Діліться фотографіями людини',
          description:
              'Діліться фотографіями людини за посиланням, до якого можуть автоматично додаватися її нові фотографії.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Установлюйте фото як шпалери',
          description:
              'Установіть фотографію як шпалери головного екрана, екрана блокування або обох.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Утримуйте для відтворення у 2×',
          description:
              'Натисніть і утримуйте відео, щоб дивитися його зі швидкістю 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'І не тільки!',
          description:
              'Ефективніше прокручування галереї та кнопки «Назад», яких легше торкатися.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'І не тільки!',
          description:
              'Ефективніше прокручування галереї, кнопки «Назад», яких легше торкатися, і поліпшене резервне копіювання.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'І не тільки!',
          description:
              'Ефективніше прокручування галереї та кнопки «Назад», яких легше торкатися.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'vi': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: 'Dải xem trước trong trình xem',
          description:
              'Hình thu nhỏ ở cuối trình xem giúp bạn chuyển nhanh hơn giữa các ảnh và video.',
        ),
        ChangeLogEntryStrings(
          title: 'Chia sẻ ảnh của một người',
          description:
              'Chia sẻ ảnh của một người bằng liên kết có thể tự động bao gồm ảnh mới của họ.',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Đặt ảnh làm hình nền',
          description:
              'Đặt một ảnh làm hình nền màn hình chính, màn hình khóa hoặc cả hai.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Nhấn giữ để phát ở tốc độ 2×',
          description: 'Nhấn và giữ video để xem ở tốc độ 2×.',
        ),
        ChangeLogEntryStrings(
          title: 'Và còn nhiều hơn thế!',
          description:
              'Cuộn thư viện hiệu quả hơn và các nút Quay lại dễ nhấn hơn.',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Và còn nhiều hơn thế!',
          description:
              'Cuộn thư viện hiệu quả hơn, các nút Quay lại dễ nhấn hơn và tính năng sao lưu được cải thiện.',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: 'Và còn nhiều hơn thế!',
          description:
              'Cuộn thư viện hiệu quả hơn và các nút Quay lại dễ nhấn hơn.',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'zh_CN': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: '查看器中的预览条',
          description: '查看器底部的缩略图可让你更快地在照片和视频之间跳转。',
        ),
        ChangeLogEntryStrings(
          title: '分享某个人的照片',
          description: '通过链接分享某个人的照片，链接中可自动加入此人的新照片。',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '将照片设为壁纸',
          description: '将照片设为主屏幕、锁定屏幕或两者的壁纸。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '长按以2×速度播放',
          description: '长按视频即可用2×速度观看。',
        ),
        ChangeLogEntryStrings(
          title: '还有更多！',
          description: '图库滚动更高效，返回按钮更易于点击。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '还有更多！',
          description: '图库滚动更高效，返回按钮更易于点击，备份也有所改进。',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '还有更多！',
          description: '图库滚动更高效，返回按钮更易于点击。',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
    'zh_TW': ChangeLogStrings(
      entries: [
        ChangeLogEntryStrings(
          title: '檢視器中的預覽列',
          description: '檢視器底部的縮圖可讓您更快地在照片與影片之間切換。',
        ),
        ChangeLogEntryStrings(
          title: '分享某個人的照片',
          description: '透過連結分享某個人的照片，連結中可自動加入此人的新照片。',
          isOnlineOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '將照片設為桌布',
          description: '將照片設為主畫面、鎖定畫面或兩者的桌布。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '長按以2×速度播放',
          description: '長按影片即可用2×速度觀看。',
        ),
        ChangeLogEntryStrings(
          title: '還有更多！',
          description: '圖片庫捲動更有效率，返回按鈕更容易點按。',
          isAndroidOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '還有更多！',
          description: '圖片庫捲動更有效率，返回按鈕更容易點按，備份也有所改善。',
          isOnlineOnly: true,
          isIOSOnly: true,
        ),
        ChangeLogEntryStrings(
          title: '還有更多！',
          description: '圖片庫捲動更有效率，返回按鈕更容易點按。',
          isLocalGalleryOnly: true,
          isIOSOnly: true,
        ),
      ],
    ),
  };
}

class ChangeLogEntryStrings {
  final String title;
  final String description;
  final bool isOnlineOnly;
  final bool isLocalGalleryOnly;
  final bool isAndroidOnly;
  final bool isIOSOnly;

  const ChangeLogEntryStrings({
    required this.title,
    required this.description,
    this.isOnlineOnly = false,
    this.isLocalGalleryOnly = false,
    this.isAndroidOnly = false,
    this.isIOSOnly = false,
  }) : assert(!(isOnlineOnly && isLocalGalleryOnly)),
       assert(!(isAndroidOnly && isIOSOnly));
}
