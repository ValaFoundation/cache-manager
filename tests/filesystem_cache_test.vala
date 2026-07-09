namespace AppTests {
    using GLib;
    using ValaFoundation.Testcases;
    using ValaFoundation.CacheManager;

    public class FilesystemCacheTest : BaseTest {
        construct {
            add_test ("filesystem-save-and-load", test_filesystem_save_and_load);
            add_test ("filesystem-json-roundtrip", test_filesystem_json_roundtrip);
            add_test ("filesystem-delete-and-clear", test_filesystem_delete_and_clear);
            add_test ("filesystem-rejects-invalid-item-type", test_filesystem_rejects_invalid_item_type);
        }

        private Value make_string_value (string value) {
            Value out_value = Value (typeof (string));
            out_value.set_string (value);
            return out_value;
        }

        private Value make_json_value (string json_text) {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data (json_text, -1);
            } catch (Error e) {
                assert_not_reached ();
            }

            Json.Node? root = parser.get_root ();
            assert (root != null);

            Value out_value = Value (typeof (Json.Node));
            out_value.set_boxed (root.copy ());
            return out_value;
        }

        private string make_temp_dir () {
            try {
                return DirUtils.make_tmp ("cache-manager-fs-test-XXXXXX");
            } catch (FileError e) {
                assert_not_reached ();
            }
        }

        private void cleanup_dir (string directory_path) {
            try {
                var dir = Dir.open (directory_path, 0);
                string? name;
                while ((name = dir.read_name ()) != null) {
                    string file_path = Path.build_filename (directory_path, name);
                    if (FileUtils.test (file_path, FileTest.IS_REGULAR)) {
                        FileUtils.remove (file_path);
                    }
                }
            } catch (FileError e) {
            }

            DirUtils.remove (directory_path);
        }

        public void test_filesystem_save_and_load () {
            string dir = make_temp_dir ();

            var cache = new ValaFoundation.CacheManager.Filesystem.Cache (dir);
            var item = new ValaFoundation.CacheManager.Filesystem.CacheItem ("token");
            item.setValue (make_string_value ("abc123"), 60);
            assert (cache.save (item));

            var cache_reload = new ValaFoundation.CacheManager.Filesystem.Cache (dir);
            CacheItemInterface? loaded = cache_reload.getItem ("token");
            assert (loaded != null);
            assert (loaded.IsHit ());

            Value? loaded_value = loaded.getValue ();
            assert (loaded_value != null);
            assert (loaded_value.get_string () == "abc123");

            cleanup_dir (dir);
        }

        public void test_filesystem_json_roundtrip () {
            string dir = make_temp_dir ();

            var cache = new ValaFoundation.CacheManager.Filesystem.Cache (dir);
            var item = new ValaFoundation.CacheManager.Filesystem.CacheItem ("json-item");
            item.setValue (make_json_value ("{\"name\":\"alice\",\"count\":2}"), 60);
            assert (cache.save (item));

            var cache_reload = new ValaFoundation.CacheManager.Filesystem.Cache (dir);
            CacheItemInterface? loaded = cache_reload.getItem ("json-item");
            assert (loaded != null);

            Value? loaded_value = loaded.getValue ();
            assert (loaded_value != null);

            Json.Node? loaded_root = (Json.Node?) loaded_value.get_boxed ();
            assert (loaded_root != null);
            assert (loaded_root.get_node_type () == Json.NodeType.OBJECT);

            Json.Object? loaded_object = loaded_root.get_object ();
            assert (loaded_object != null);
            assert (loaded_object.get_string_member ("name") == "alice");
            assert ((int) loaded_object.get_int_member ("count") == 2);

            cleanup_dir (dir);
        }

        public void test_filesystem_delete_and_clear () {
            string dir = make_temp_dir ();
            var cache = new ValaFoundation.CacheManager.Filesystem.Cache (dir);

            var a = new ValaFoundation.CacheManager.Filesystem.CacheItem ("a");
            a.setValue (make_string_value ("1"), 60);
            var b = new ValaFoundation.CacheManager.Filesystem.CacheItem ("b");
            b.setValue (make_string_value ("2"), 60);

            assert (cache.saveItems ({a, b}));
            assert (cache.hasItem ("a"));
            assert (cache.hasItem ("b"));

            assert (cache.deleteItem ("a"));
            assert (!cache.hasItem ("a"));
            assert (cache.hasItem ("b"));

            assert (cache.clear ());
            assert (!cache.hasItem ("b"));

            cleanup_dir (dir);
        }

        public void test_filesystem_rejects_invalid_item_type () {
            string dir = make_temp_dir ();
            var cache = new ValaFoundation.CacheManager.Filesystem.Cache (dir);
            var dummy = new DummyCacheItem ("dummy");

            assert (!cache.save (dummy));
            assert (cache.getItem ("dummy") == null);

            cleanup_dir (dir);
        }
    }
}
