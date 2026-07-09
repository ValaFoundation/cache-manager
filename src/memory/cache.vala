namespace ValaFoundation.CacheManager.Memory {
    using ValaFoundation.CacheManager;
    using Gee;

    public class Cache : Object, CacheInterface {
        private HashMap<string, CacheItem> items;
        private RWLock rw_lock;

        public Cache () {
            this.items = new HashMap<string, CacheItem> ();
            this.rw_lock = RWLock ();
        }

        public CacheItemInterface? getItem (string key) {
            this.rw_lock.reader_lock ();
            CacheItem? item = this.items.get (key);
            this.rw_lock.reader_unlock ();
            return item;
        }

        public CacheItemInterface[] getItems (string[] keys) {
            this.rw_lock.reader_lock ();
            var result = new ArrayList<CacheItemInterface> ();
            foreach (string key in keys) {
                CacheItem? item = this.items.get (key);
                if (item != null) {
                    result.add (item);
                }
            }
            this.rw_lock.reader_unlock ();

            CacheItemInterface[] out = new CacheItemInterface[result.size];
            int i = 0;
            foreach (CacheItemInterface item in result) {
                out[i++] = item;
            }
            return out;
        }

        public bool hasItem (string key) {
            CacheItemInterface? item = this.getItem (key);
            if (item == null) {
                return false;
            }

            return item.IsHit ();
        }

        public bool clear () {
            this.rw_lock.writer_lock ();
            this.items = new HashMap<string, CacheItem> ();
            this.rw_lock.writer_unlock ();
            return true;
        }

        public bool deleteItem (string key) {
            this.rw_lock.writer_lock ();
            this.items.unset (key);
            this.rw_lock.writer_unlock ();
            return true;
        }

        public bool deleteItems (string[] keys) {
            this.rw_lock.writer_lock ();
            foreach (string key in keys) {
                this.items.unset (key);
            }
            this.rw_lock.writer_unlock ();
            return true;
        }

        public bool save (CacheItemInterface item) {
            CacheItem? memory_item = item as CacheItem;
            if (memory_item == null) {
                return false;
            }

            this.rw_lock.writer_lock ();
            this.items.set (memory_item.getKey (), memory_item);
            this.rw_lock.writer_unlock ();
            return true;
        }

        public bool saveItems (CacheItemInterface[] items) {
            foreach (CacheItemInterface item in items) {
                if (!this.save (item)) {
                    return false;
                }
            }

            return true;
        }

        public bool saveDeferred (CacheItemInterface item) {
            return this.save (item);
        }

        public bool commit () {
            return true;
        }

    }
}
