package test;

class Assert {
    public static function assertEquals(expected:Dynamic, actual:Dynamic, message:String = ""):Bool {
        if (expected == actual) {
            return true;
        } else {
            trace("FAIL: " + (message != "" ? message + " | " : "") + "Expected: " + Std.string(expected) + ", Actual: " + Std.string(actual));
            return false;
        }
    }

    public static function assertTrue(condition:Bool, message:String = ""):Bool {
        if (condition) {
            return true;
        } else {
            trace("FAIL: " + message);
            return false;
        }
    }

    public static function assertFalse(condition:Bool, message:String = ""):Bool {
        if (!condition) {
            return true;
        } else {
            trace("FAIL: " + message);
            return false;
        }
    }
}
