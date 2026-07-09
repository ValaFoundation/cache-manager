namespace AppTests {
    using GLib;
    using ValaFoundation.Testcases;
    using ValaFoundation.CacheManager;

    internal class DummyCacheItem : Object, CacheItemInterface {
        private string key;

        public DummyCacheItem (string key) {
            this.key = key;
        }

        public string getKey () {
            return this.key;
        }

        public Value? getValue () {
            return null;
        }

        public bool IsHit () {
            return true;
        }

        public CacheItemInterface setValue (Value? value, int ttl = 0) {
            return this;
        }

        public CacheItemInterface expireAfter (int ttl) {
            return this;
        }

        public CacheItemInterface expireAt (int timestamp) {
            return this;
        }
    }

    public class MemoryCacheTest : BaseTest {
        construct {
            add_test ("memory-save-get-has", test_memory_save_get_has);
            add_test ("memory-get-items-filters-missing", test_memory_get_items_filters_missing);
            add_test ("memory-delete-and-clear", test_memory_delete_and_clear);
            add_test ("memory-rejects-invalid-item-type", test_memory_rejects_invalid_item_type);
        }

        private Value make_string_value (string value) {
            Value out_value = Value (typeof (string));
            out_value.set_string (value);
            return out_value;
        }

        public void test_memory_save_get_has () {
            var cache = new ValaFoundation.CacheManager.Memory.Cache ();
            var item = new ValaFoundation.CacheManager.Memory.CacheItem ("user:1");
            item.setValue (make_string_value ("alice"), 60);

            assert (cache.save (item));
            assert (cache.hasItem ("user:1"));

            CacheItemInterface? fetched = cache.getItem ("user:1");
            assert (fetched != null);
            assert (fetched.IsHit ());

            Value? fetched_value = fetched.getValue ();
            assert (fetched_value != null);
            assert (fetched_value.get_string () == "alice");
        }

        public void test_memory_get_items_filters_missing () {
            var cache = new ValaFoundation.CacheManager.Memory.Cache ();
            var item = new ValaFoundation.CacheManager.Memory.CacheItem ("k1");
            item.setValue (make_string_value ("v1"), 60);

            assert (cache.save (item));

            CacheItemInterface[] items = cache.getItems ({"k1", "missing"});
            assert (items.length == 1);
            assert (items[0].getKey () == "k1");
        }

        public void test_memory_delete_and_clear () {
            var cache = new ValaFoundation.CacheManager.Memory.Cache ();

            var item_1 = new ValaFoundation.CacheManager.Memory.CacheItem ("a");
            item_1.setValue (make_string_value ("1"), 60);
            var item_2 = new ValaFoundation.CacheManager.Memory.CacheItem ("b");
            item_2.setValue (make_string_value ("2"), 60);

            assert (cache.saveItems ({item_1, item_2}));
            assert (cache.hasItem ("a"));
            assert (cache.hasItem ("b"));

            assert (cache.deleteItem ("a"));
            assert (!cache.hasItem ("a"));
            assert (cache.hasItem ("b"));

            assert (cache.clear ());
            assert (!cache.hasItem ("a"));
            assert (!cache.hasItem ("b"));
        }

        public void test_memory_rejects_invalid_item_type () {
            var cache = new ValaFoundation.CacheManager.Memory.Cache ();
            var dummy = new DummyCacheItem ("dummy");

            assert (!cache.save (dummy));
            assert (cache.getItem ("dummy") == null);
        }
    }
}
