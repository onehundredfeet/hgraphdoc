package gdoc;


interface MinHeapable {
}

@:generic
class MinHeapExternalItem<T> {
    public var item:T;
    public var priority:Float;
    public var index:Int;

    public function new(item:T, priority:Float) {
        this.item = item;
        this.priority = priority;
    }
}


@:generic
class MinHeapExternal<T : MinHeapable> {
    private var heap:Array<MinHeapExternalItem<T>>;
    private var itemToHeapItem:haxe.ds.Map<T, MinHeapExternalItem<T>>;

    public function new() {
        heap = [];
        itemToHeapItem = new Map<T, MinHeapExternalItem<T>>();
    }

    public function insert(item:T, priority:Float):Void {
        var node = new MinHeapExternalItem(item,  priority);
        heap.push(node);
        var index = heap.length - 1;
        node.index = index;
        itemToHeapItem.set(item, node);
        heapifyUp(index);
    }

    // Smallest item has the highest priority
    public function pop():T {
        if (heap.length == 0) {
            throw "Heap is empty";
        }
        var minNode = heap[0];
        var minItem = minNode.item;
        minNode.index = -1;
        if (heap.length == 1) {
            heap.pop();
        } else {
            heap[0] = heap.pop();
            heap[0].index = 0;
            heapifyDown(0);
        }
        return minItem;
    }


    public function peek():T {
        if (heap.length == 0) {
            return null;
        }
        return heap[0].item;
    }

    public function isEmpty():Bool {
        return heap.length == 0;
    }

    public function decreaseKey(item:T, newPriority:Float):Void {
        var node = itemToHeapItem.get(item);
        if (node == null) {
            throw "Item not found in heap";
        }
        if (node.index < 0) {
            throw "Item is not in heap";
        }
        if (heap[node.index].priority <= newPriority) {
            throw "New priority must be less than current priority";
        }
        heap[node.index].priority = newPriority;
        heapifyUp(node.index);
    }

     //Restores the heap property going up from the given index.
    private function heapifyUp(index:Int):Void {
        var currentIndex = index;
        while (currentIndex > 0) {
            var parentIndex = (currentIndex - 1) >> 1;
            if (heap[currentIndex].priority < heap[parentIndex].priority) {
                swap(currentIndex, parentIndex);
                currentIndex = parentIndex;
            } else {
                break;
            }
        }
    }

     //Restores the heap property going down from the given index.
    private function heapifyDown(index:Int):Void {
        var currentIndex = index;
        var length = heap.length;
        while (true) {
            var leftChildIndex = (currentIndex << 1) + 1;
            var rightChildIndex = (currentIndex << 1) + 2;
            var smallestIndex = currentIndex;

            if (leftChildIndex < length && heap[leftChildIndex].priority < heap[smallestIndex].priority) {
                smallestIndex = leftChildIndex;
            }
            if (rightChildIndex < length && heap[rightChildIndex].priority < heap[smallestIndex].priority) {
                smallestIndex = rightChildIndex;
            }
            if (smallestIndex != currentIndex) {
                swap(currentIndex, smallestIndex);
                currentIndex = smallestIndex;
            } else {
                break;
            }
        }
    }

    private inline function swap(i:Int, j:Int):Void {
        var temp = heap[i];
        heap[i] = heap[j];
        heap[j] = temp;

        heap[i].index = i;
        heap[j].index = j;
    }
}

@:allow(MinHeapAbstract)
class AMinHeapItem {
    private var priority:Float;
    private var index:Int = -1;

    public inline function new() {
    }
}


@:generic
@:access(gdoc.MinHeapAbstract)
abstract MinHeapAbstract<T : AMinHeapItem>(Array<T>) {
    public function new() {
        this = new Array<T>();
    }
    public function insert(item:T, priority:Float):Void {
        if (item.index != -1) {
            throw "Item is already in the heap";
        }
        this.push(item);
        var index = this.length - 1;
        item.index = index;
        item.priority = priority;
        heapifyUp(index);
    }

    public inline function contains(item:T):Bool {
        if (item.index == -1 || item.index >= this.length) {
            return false;
        }
        
        return this[item.index] == item;
    }
    // Smallest item has the highest priority
    public function pop():T {
        if (this.length == 0) {
            throw "Heap is empty";
        }
        var minNode = this[0];
        minNode.index = -1;
        if (this.length == 1) {
            this.pop();
        } else {
            this[0] = this.pop();
            this[0].index = 0;
            heapifyDown(0);
        }
        return minNode;
    }


    public function peek():T {
        if (this.length == 0) {
            return null;
        }
        return this[0];
    }

    public function isEmpty():Bool {
        return this.length == 0;
    }

    public function decreaseKey(item:T, newPriority:Float):Void {
        if (item.index < 0) {
            throw "Item is not in heap";
        }
        if (item.priority <= newPriority) {
            throw "New priority must be less than current priority";
        }
        item.priority = newPriority;
        heapifyUp(item.index);
    }

     //Restores the heap property going up from the given index.
    private function heapifyUp(index:Int):Void {
        var currentIndex = index;
        while (currentIndex > 0) {
            var parentIndex = (currentIndex - 1) >> 1;
            if (this[currentIndex].priority < this[parentIndex].priority) {
                swap(currentIndex, parentIndex);
                currentIndex = parentIndex;
            } else {
                break;
            }
        }
    }

     //Restores the heap property going down from the given index.
    private function heapifyDown(index:Int):Void {
        var currentIndex = index;
        var length = this.length;
        while (true) {
            var leftChildIndex = (currentIndex << 1) + 1;
            var rightChildIndex = (currentIndex << 1) + 2;
            var smallestIndex = currentIndex;

            if (leftChildIndex < length && this[leftChildIndex].priority < this[smallestIndex].priority) {
                smallestIndex = leftChildIndex;
            }
            if (rightChildIndex < length && this[rightChildIndex].priority < this[smallestIndex].priority) {
                smallestIndex = rightChildIndex;
            }
            if (smallestIndex != currentIndex) {
                swap(currentIndex, smallestIndex);
                currentIndex = smallestIndex;
            } else {
                break;
            }
        }
    }
    

    private inline function swap(i:Int, j:Int):Void {
        var temp = this[i];
        this[i] = this[j];
        this[j] = temp;

        this[i].index = i;
        this[j].index = j;
    }
}

typedef MinHeap<T: AMinHeapItem> = MinHeapAbstract<T>;