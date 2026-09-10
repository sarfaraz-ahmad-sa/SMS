import unittest
from prepare_release import allowed, PATTERNS

class ReleaseSafetyTests(unittest.TestCase):
    def test_private_and_generated_paths_are_excluded(self):
        for name in ['.git/config','.vercel/project.json','config/demo.json',
                     'android/key.properties','android/local.properties',
                     'ios/Runner/GoogleService-Info.plist','functions/node_modules/a/index.js',
                     'web/icons/Icon-192.png','assets/setting.gif','build/web/main.dart.js']:
            self.assertFalse(allowed(name), name)

    def test_required_public_source_is_allowed(self):
        for name in ['lib/main.dart','config/brand.example.json','.env.example',
                     'assets/school-mark.svg','supabase/migrations/202609100020_active_portal_membership.sql']:
            self.assertTrue(allowed(name), name)

    def test_high_confidence_secrets_are_detected_without_echoing(self):
        values = ['sb_'+'secret_'+'x'*30, '-----BEGIN '+'PRIVATE KEY-----',
                  'postgresql://'+'username:password@localhost/example']
        for value in values:
            self.assertTrue(any(pattern.search(value) for pattern in PATTERNS.values()))

if __name__ == '__main__':
    unittest.main()
