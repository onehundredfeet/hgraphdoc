package grph;

#if seedyrng
@:forward.new
abstract Random(seedyrng.Random) {
    public inline function random() {
        return this.random();
    }
    public inline function randomInt(min : Int, max : Int) {
        return this.randomInt(min, max);
    }
    public inline function shuffle<T>(array:Array<T>) {
        this.shuffle(array);
    }
    public inline function choice<T>(array:Array<T>) {
        return this.choice(array);
    }
    public inline function random2Pi() : Float {
        return this.random() * (Math.PI * 2.);
    }
    public inline function range(min:Float, max:Float) : Float {
        return this.uniform(min, max);
    }
}
#else
class Random {
    public inline function new(seed : haxe.Int64 = 0) {

    }
    public inline function random() {
        return Math.random();
    }

    public inline function randomInt(min : Int, max : Int) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }
    public inline shuffle<T>(array:Array<T>) {
        for (i in 0...array.length) {
            var j = this.randomInt(0, array.length - 1);
            var tmp = array[i];
            array[i] = array[j];
            array[j] = tmp;
        }
    }
    public inline function choice<T>(array:Array<T>) {
        return array[this.randomInt(0, array.length - 1)];
    }
    public inline function random2Pi() : Float {
        return this.random() * (Math.PI * 2.);
    }
    public inline function range(min:Float, max:Float) : Float {
        return this.random() * (max - min) + min;
    }
}
#end