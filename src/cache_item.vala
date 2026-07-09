namespace ValaFoundation.CacheManager {

    public interface CacheItem : Object {
        public abstract string getKey ();
        public abstract Value? getValue ();
        public abstract bool IsHit ();
        public abstract CacheItem setValue (Value? value, int ttl = 0);
        public abstract CacheItem expireAfter (int ttl);
        public abstract CacheItem expireAt (int timestamp);
    }
}
