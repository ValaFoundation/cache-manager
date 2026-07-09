namespace ValaFoundation.CacheManager {

    public interface CacheItemInterface : Object {
        public abstract string getKey ();
        public abstract Value? getValue ();
        public abstract bool IsHit ();
        public abstract CacheItemInterface setValue (Value? value, int ttl = 0);
        public abstract CacheItemInterface expireAfter (int ttl);
        public abstract CacheItemInterface expireAt (int timestamp);
    }
}
