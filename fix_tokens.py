import re

FILES = [
    "lib/screens/shared/xray_upload_screen.dart",
    "lib/screens/doctor/xray_doctor_screen.dart",
    "lib/screens/shared/profile_screen.dart",
]

SUBS = [
    (r'AppRadius\.card\b',  'AppRadius.xl'),
    (r'AppRadius\.pill\b',  'AppRadius.xxl'),
    (r'AppRadius\.field\b', 'AppRadius.md'),
    (r'AppText\.headline2\b', 'AppText.headingMd'),
    (r'AppText\.headline1\b', 'AppText.headingLg'),
    (r'AppText\.body\b',    'AppText.bodyLg'),
    (r'AppColors\.textTertiary\b', 'AppColors.textMuted'),
    (r'\bloading:\s*', 'isLoading: '),
    (r'\baccent:\s*(AppColors\.\w+)',  r'color: \1'),
    (r',\s*disabled:\s*\S+', ''),
    (r'\bicon:\s*Icons\.', 'trailingIcon: Icons.'),
]

for path in FILES:
    with open(path) as f:
        src = f.read()
    out = src
    for pattern, repl in SUBS:
        out = re.sub(pattern, repl, out)
    if out != src:
        with open(path, 'w') as f:
            f.write(out)
        print("  fixed " + path)
    else:
        print("  no changes " + path)
print("done")
