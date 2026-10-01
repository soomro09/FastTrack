/// Custom illustration SVGs used sparingly across the app — for milestone
/// moments and empty states only. Kept in one consistent visual language:
/// soft two-tone gradients, rounded geometry, minimal element count.
class AppSvgs {
  // 1. Trophy — goal-reached celebration dialog.
  static const String trophyAchievement = '''
<svg viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="trophyGold" x1="30" y1="20" x2="90" y2="100" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FDE68A"/>
      <stop offset="100%" stop-color="#D97706"/>
    </linearGradient>
    <radialGradient id="trophyGlow" cx="50%" cy="45%" r="60%">
      <stop offset="0%" stop-color="#14B8A6" stop-opacity="0.16"/>
      <stop offset="100%" stop-color="#14B8A6" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <circle cx="60" cy="58" r="52" fill="url(#trophyGlow)"/>
  <path d="M36 34C26 34 22 42 26 50C28.7 55.4 33.3 59 38 61" stroke="url(#trophyGold)" stroke-width="4.5" stroke-linecap="round"/>
  <path d="M84 34C94 34 98 42 94 50C91.3 55.4 86.7 59 82 61" stroke="url(#trophyGold)" stroke-width="4.5" stroke-linecap="round"/>
  <path d="M36 30H84V50C84 68.2254 73.8823 80 60 80C46.1177 80 36 68.2254 36 50V30Z" fill="url(#trophyGold)"/>
  <rect x="32" y="25" width="56" height="8" rx="4" fill="#FCD34D"/>
  <path d="M60 40L62.5 45.2L68 46L64 49.8L65 55.2L60 52.4L55 55.2L56 49.8L52 46L57.5 45.2Z" fill="#FFFBEB"/>
  <rect x="54" y="80" width="12" height="13" rx="2" fill="#B45309"/>
  <path d="M42 100C42 96.134 45.134 93 49 93H71C74.866 93 78 96.134 78 100V101H42V100Z" fill="#92400E"/>
</svg>
''';

  // 2. Fasting Rhythm — a two-tone ring split by fasting/eating proportion,
  // echoing the main timer ring. Plans screen header accent.
  static const String fastingRhythm = '''
<svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="fastArc" x1="10" y1="10" x2="60" y2="90" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2DD4BF"/>
      <stop offset="100%" stop-color="#0F766E"/>
    </linearGradient>
    <linearGradient id="eatArc" x1="20" y1="70" x2="60" y2="10" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#D98F5F"/>
      <stop offset="100%" stop-color="#C2703D"/>
    </linearGradient>
  </defs>
  <circle cx="50" cy="50" r="19" fill="#14B8A6" fill-opacity="0.08"/>
  <path d="M50 12A38 38 0 1 1 17.1 69" stroke="url(#fastArc)" stroke-width="9" stroke-linecap="round"/>
  <path d="M17.1 69A38 38 0 0 1 50 12" stroke="url(#eatArc)" stroke-width="9" stroke-linecap="round"/>
</svg>
''';

  // 3a. Empty History — static ring only; hands are drawn/animated
  // separately by TickingClockIcon so they can tick independently.
  static const String emptyHistoryFace = '''
<svg viewBox="0 0 140 140" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="clockRing" x1="20" y1="20" x2="120" y2="120" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2DD4BF"/>
      <stop offset="100%" stop-color="#C2703D"/>
    </linearGradient>
  </defs>
  <circle cx="70" cy="70" r="58" fill="#14B8A6" fill-opacity="0.06"/>
  <circle cx="70" cy="70" r="42" stroke="url(#clockRing)" stroke-width="5"/>
</svg>
''';

  // 3b. Kept as a static fallback / for reuse elsewhere.
  static const String emptyHistory = '''
<svg viewBox="0 0 140 140" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="clockRing" x1="20" y1="20" x2="120" y2="120" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2DD4BF"/>
      <stop offset="100%" stop-color="#C2703D"/>
    </linearGradient>
  </defs>
  <circle cx="70" cy="70" r="58" fill="#14B8A6" fill-opacity="0.06"/>
  <circle cx="70" cy="70" r="42" stroke="url(#clockRing)" stroke-width="5"/>
  <line x1="70" y1="70" x2="70" y2="46" stroke="#0F766E" stroke-width="4.5" stroke-linecap="round"/>
  <line x1="70" y1="70" x2="90" y2="70" stroke="#C2703D" stroke-width="4.5" stroke-linecap="round"/>
  <circle cx="70" cy="70" r="5.5" fill="#FFFFFF"/>
  <circle cx="70" cy="70" r="5.5" stroke="url(#clockRing)" stroke-width="2"/>
</svg>
''';

  // 4. Water Drop — hydration tracker badge icon.
  static const String waterDrop = '''
<svg viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="dropGrad" x1="14" y1="10" x2="62" y2="70" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#60A5FA"/>
      <stop offset="100%" stop-color="#2563EB"/>
    </linearGradient>
  </defs>
  <path d="M40 8C40 8 18 34 18 50C18 61.0457 27.6112 70 40 70C52.3888 70 62 61.0457 62 50C62 34 40 8 40 8Z" fill="url(#dropGrad)"/>
  <path d="M31 26C31 26 22 40 22 49" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="4" stroke-linecap="round"/>
</svg>
''';

  // 5. Empty Weight — minimal scale for the no-data chart state.
  static const String emptyWeight = '''
<svg viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="scaleGrad" x1="20" y1="20" x2="100" y2="100" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#14B8A6"/>
      <stop offset="100%" stop-color="#65A30D"/>
    </linearGradient>
  </defs>
  <circle cx="60" cy="60" r="52" fill="#14B8A6" fill-opacity="0.06"/>
  <rect x="26" y="26" width="68" height="68" rx="20" stroke="url(#scaleGrad)" stroke-width="4.5"/>
  <rect x="44" y="42" width="32" height="14" rx="7" fill="url(#scaleGrad)" fill-opacity="0.16"/>
  <circle cx="60" cy="49" r="4" fill="url(#scaleGrad)"/>
  <path d="M48 68C48 68 53 72 60 72C67 72 72 68 72 68" stroke="url(#scaleGrad)" stroke-width="4" stroke-linecap="round"/>
</svg>
''';

  // 6. Streak Flame — inline streak-counter icon.
  static const String streakFlame = '''
<svg viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="flameOuter" x1="14" y1="6" x2="46" y2="52" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FBBF24"/>
      <stop offset="100%" stop-color="#DC2626"/>
    </linearGradient>
    <linearGradient id="flameInner" x1="22" y1="24" x2="38" y2="48" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FEF3C7"/>
      <stop offset="100%" stop-color="#F97316"/>
    </linearGradient>
  </defs>
  <path d="M30 4C30 4 42 20 42 32C42 41.9411 36.6274 50 28 50C19.3726 50 14 41.9411 14 32C14 26 17 20 21 16C19.5 22 21.5 25.5 25 25C28 24.5 28 19.5 25.5 15C27.5 11 30 7.5 30 4Z" fill="url(#flameOuter)"/>
  <path d="M28 26C28 26 34 34 34 40C34 44.4183 31.3137 48 27 48C22.6863 48 19 44.4183 19 40C19 36.5 21 33.5 23.5 31.5C22.5 34.5 24 36.5 26 36C27.8 35.5 27.5 32 26 29.5C27 28 28 27 28 26Z" fill="url(#flameInner)"/>
</svg>
''';
}
