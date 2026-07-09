namespace ValaFoundation.CacheManager {

    public const int64 DEFAULT_TTL = 0;
    public const int64 TTL_MINUTE = 60;
    public const int64 TTL_HOUR = 3600;
    public const int64 TTL_DAY = 86400;
    public const int64 TTL_WEEK = 604800;
    public const int64 TTL_MONTH = 2592000;
    public const int64 TTL_YEAR = 31536000;
    public const int64 TTL_INFINITE = -1;

    public interface Cache : Object {
        public abstract CacheItem getItem (string key);
        public abstract CacheItem[] getItems (string[] keys);
        public abstract bool hasItem (string key);
        public abstract bool clear ();
        public abstract bool deleteItem (string key);
        public abstract bool deleteItems (string[] keys);
        public abstract bool save (CacheItem item);
        public abstract bool saveItems (CacheItem[] items);
        public abstract bool saveDeferred (CacheItem item);
        public abstract bool commit ();

    }
}
