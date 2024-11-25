package grph;

import haxe.io.BytesOutput;
import hl.Bytes;
import sys.io.File;
import grph.IndexedAttributeTriMesh;
using Lambda;

class GLTFElement {
    public var index: Int;
}
class GLTFNode extends GLTFElement{
    public var mesh : GLTFMesh;
    public var children = new Array<GLTFNode>();
    public var translation = [0,0,0];
    public var name : String;

    public function new() {

    }
}

class GLTFScene  extends GLTFElement{
    public function new() {

    }
}

class GLTFMeshAttribute  {
    public var accessor : GLTFAccessor;
    public var semantic : String;

    public function new() {

    }
}
enum abstract GLTFPrimitiveMode(Int) from Int to Int {
    var PT_POINTS = 0;
    var PT_LINES = 1;
    var PT_LINE_LOOP = 2;
    var PT_LINE_STRIP = 3;
    var PT_TRIANGLES = 4;
    var PT_TRIANGLE_STRIP = 5;
    var PT_TRIANGLE_FAN = 6;
}

class GLTFMeshPrimitives {
    public var attributes = new Array<GLTFMeshAttribute>();
    public var indices : GLTFAccessor;
    public var material : GLTFMaterial;
    public var mode : GLTFPrimitiveMode = GLTFPrimitiveMode.PT_TRIANGLES;
    public function new() {

    }
}

class GLTFMesh  extends GLTFElement{
    public var primitives = new Array<GLTFMeshPrimitives>();
    public function new() {

    }
}

class GLTFMaterial  extends GLTFElement{
    public var doubleSided : Bool = true;
    public var name : String = "";
    public var kind = "pbrMetallicRoughness";
    public var baseColorFactor : Array<Float> = [1., 1., 1., 1.];
    public var metallicFactor : Float = 0.;
    public var roughnessFactor : Float = 0.5;
    public function new() {

    }
}

class GLTFTexture  extends GLTFElement{
    public function new() {

    }
}

class GLTFImage  extends GLTFElement{
    public function new() {

    }
}

class GLTFBuffer  extends GLTFElement{
    public function new() {

    }
    public var data : haxe.io.Bytes;

}

enum abstract GLTFBufferViewTarget(Int) from Int to Int {
    var BT_ARRAY_BUFFER = 34962;
    var BT_ELEMENT_ARRAY_BUFFER = 34963;
}
class GLTFBufferView  extends GLTFElement{
    public var buffer : GLTFBuffer;
    public var byteLength : Int;
    public var byteOffset : Int;
    public var target : GLTFBufferViewTarget;

    public function new() {

    }

}

/*
{
			"bufferView":0,
			"componentType":5126,
			"count":4,
			"max":[
				10,
				10,
				0
			],
			"min":[
				0,
				0,
				0
			],
			"type":"VEC3"
		},
*/

enum abstract GLTFComponentType(Int) from Int to Int {
    var CT_BYTE = 5120;
    var CT_UNSIGNED_BYTE = 5121;
    var CT_SHORT = 5122;
    var CT_UNSIGNED_SHORT = 5123;
    var CT_UNSIGNED_INT = 5125;
    var CT_FLOAT = 5126;
}

enum abstract GLTFAccessorType(String) from String to String {
    var AT_SCALAR = "SCALAR";
    var AT_VEC2 = "VEC2";
    var AT_VEC3 = "VEC3";
    var AT_VEC4 = "VEC4";
    var AT_MAT2 = "MAT2";
    var AT_MAT3 = "MAT3";
    var AT_MAT4 = "MAT4";
}

class GLTFAccessor  extends GLTFElement{
    public var bufferView : GLTFBufferView;
    public var componentType : GLTFComponentType;
    public var count : Int;
    public var max : Array<Float>;
    public var min : Array<Float>;
    public var type : GLTFAccessorType;

    public function new() {

    }
}


class GLTFBufferBuilder {
    public function new() {

    }
    var _writer = new BytesOutput();
    var _writeHead = 0;
    var _blockStart = 0;
    var _blockEnd = 0;

    public function beginBlock() {
        _blockStart = _writeHead;
    }
    public function endBlock() : { start:Int, end:Int } {
        _blockEnd = _writeHead;
        return { start: _blockStart, end: _blockEnd };
    }

    public function writeFloatAsSingles(data:Array<Float>) {
        for (v in data) {
            _writer.writeFloat(v);
        }
        _writeHead += 4 * data.length;
    }

    public function writeInt32s(data:Array<Int>) {
        for (v in data) {
            _writer.writeInt32(v);
        }
        _writeHead += 4 * data.length;
    }

    public function finishAndGetBytes() : haxe.io.Bytes {
        return _writer.getBytes();
    }
}

class GLTFWriter {

    public function new() {

    }

    var nodes = new Array<GLTFNode>();
    var meshes = new Array<GLTFMesh>();
    var accessors = new Array<GLTFAccessor>();
    var buffers = new Array<GLTFBuffer>();
    var bufferViews = new Array<GLTFBufferView>();
    var materials = new Array<GLTFMaterial>();

    function addMesh() : GLTFMesh {
        var mesh = new GLTFMesh();
        mesh.index = meshes.length;
        meshes.push(mesh);
        return mesh;
    }
    function addNode() : GLTFNode {
        var node = new GLTFNode();
        node.index = nodes.length;
        nodes.push(node);
        return node;
    }
    function addAccessor(bufferView : GLTFBufferView = null) : GLTFAccessor {
        var accessor = new GLTFAccessor();
        accessor.index = accessors.length;
        accessor.bufferView = bufferView;
        accessors.push(accessor);
        return accessor;
    }
    function addBuffer() : GLTFBuffer {
        var buffer = new GLTFBuffer();
        buffer.index = buffers.length;
        buffers.push(buffer);
        return buffer;
    }
    function addBufferView(target : GLTFBufferViewTarget, buffer : GLTFBuffer = null) : GLTFBufferView {
        var bufferView = new GLTFBufferView();
        bufferView.target = target;
        bufferView.index = bufferViews.length;
        bufferView.buffer = buffer;
        bufferViews.push(bufferView);
        return bufferView;
    }

    function addMaterial() {
        var m = new GLTFMaterial();
        m.index = materials.length;
        materials.push(m);
        return m;
    }

    public function addDefaultMaterial() {
        var m = addMaterial();
        m.name = "Default";
        return m;
    }

    public function addTriMeshesAsClusters(triMeshes:Array<{mesh: IndexedAttributeTriMesh, material:GLTFMaterial}>, name:String) {


        var mesh = addMesh();
        var buffer = addBuffer();
        var bufferBuilder = new GLTFBufferBuilder();

        var totalVerts = triMeshes.fold((v, accum) -> accum + v.mesh.getVertCount(), 0);

        // tally data
        for (triMeshTouple in triMeshes) {
            var triMesh = triMeshTouple.mesh;
        
            var posMin = [Math.POSITIVE_INFINITY,Math.POSITIVE_INFINITY,Math.POSITIVE_INFINITY];
            var posMax = [Math.NEGATIVE_INFINITY,Math.NEGATIVE_INFINITY,Math.NEGATIVE_INFINITY];
            var posCount = totalVerts;
            var positions = triMesh.getVertexAttributesF(AttributeSemantic.POSITION);

            for (i in 0...posCount) {
                var x = positions[i * 3 + 0];
                var y = positions[i * 3 + 1];
                var z = positions[i * 3 + 2];

                if (x < posMin[0]) posMin[0] = x;
                if (y < posMin[1]) posMin[1] = y;
                if (z < posMin[2]) posMin[2] = z;
                if (x > posMax[0]) posMax[0] = x;
                if (y > posMax[1]) posMax[1] = y;
                if (z > posMax[2]) posMax[2] = z;
            }

            var posBufferView = addBufferView(BT_ARRAY_BUFFER, buffer);
            bufferBuilder.beginBlock();
            bufferBuilder.writeFloatAsSingles(positions);
            var block = bufferBuilder.endBlock();

            posBufferView.byteLength = block.end - block.start;
            posBufferView.byteOffset = block.start;

            if (posBufferView.byteLength != posCount * 3 * 4) {
                throw "Invalid buffer length";
            }
            if (posBufferView.byteOffset != 0) {
                throw "Invalid buffer offset";
            }
            var indexBufferView = addBufferView(BT_ELEMENT_ARRAY_BUFFER, buffer);
            bufferBuilder.beginBlock();
            bufferBuilder.writeInt32s(triMesh.indices);
            block = bufferBuilder.endBlock();
            indexBufferView.byteLength = block.end - block.start;
            indexBufferView.byteOffset = block.start;

            var posAccessor = addAccessor(posBufferView);
            posAccessor.max = posMax;
            posAccessor.min = posMin;
            posAccessor.componentType = GLTFComponentType.CT_FLOAT;
            posAccessor.count = triMesh.getVertCount(); //?
            posAccessor.type = GLTFAccessorType.AT_VEC3;

            var indexAccessor = addAccessor(indexBufferView);
            indexAccessor.componentType = GLTFComponentType.CT_UNSIGNED_INT;
            indexAccessor.count = triMesh.indices.length;
            indexAccessor.type = GLTFAccessorType.AT_SCALAR;

            var attr = new GLTFMeshAttribute();
            attr.accessor = posAccessor;
            attr.semantic = "POSITION";

            var prim = new GLTFMeshPrimitives();
            prim.material = triMeshTouple.material;
            prim.attributes.push(attr);
            prim.indices = indexAccessor;
            mesh.primitives.push(prim);
        
        }
        buffer.data = bufferBuilder.finishAndGetBytes();

        var node = addNode();
        node.mesh = mesh;
        node.name = name;
    }

    public function addTriMesh(triMesh:IndexedAttributeTriMesh, material: GLTFMaterial, name:String = null) {
        addTriMeshesAsClusters([{mesh: triMesh, material: material}], name);
    }
    public function finishAndWrite(path:String) {
        var buffer = new StringBuf();
        var indent = 0;
        var lastLine = null;
        var lastIndent = 0;        
        function addLine(line:String) {
            if (lastLine != null) {
                for (_ in 0...lastIndent) buffer.add('\t');
                buffer.add(lastLine);
                buffer.add('\n');
            }
            lastLine = line;
            lastIndent = indent;
        }
        function push(){
            indent++;
        }
        function pop(){
            indent--;
        }
        function endList(){
            // remove last comma
            lastLine = lastLine.substring(0, lastLine.length - 1);
            addLine(null);
        }
        function finish() {
            if (lastLine != null) {
                addLine(null);
            }
        }

       
        addLine('{');
        push();
        addLine('"asset": {');
        push();
        addLine('"version": "2.0",');
        addLine('"generator": "hxgltf"');
        pop();
        addLine('},');
        addLine('"scene":0,');
        addLine('"scenes": [{');
        push();
        addLine('"name": "Scene",');
        addLine('"nodes": [');
        push();
        for (n in nodes) {
            addLine('' + n.index + ',');
        }
        endList();
        pop();
        addLine(']');
        pop();
        addLine('}],');
        addLine('"nodes": [');
        push();
        for (n in nodes) {
            addLine('{');
            push();
            addLine('"name": "${n.name == null ? 'Node${n.index}' : n.name}",');
            if (n.children.length > 0) {
                addLine('"children": [');
                push();
                for (c in n.children) {
                    addLine('"' + c.index + '",');
                }
                pop();
                addLine('],');
            }
            else
            if (n.mesh != null) {
                addLine('"mesh": ' + n.mesh.index + ',');
            }
            addLine('"translation": ${n.translation}');
            pop();
            addLine('},');
        }
        endList();
        pop();
        addLine('],');
        addLine('"materials": [');
        for (m in materials) {
            addLine('{');
            push();
            addLine('"doubleSided":${m.doubleSided},');
            addLine('"name":"${m.name}",');
            addLine('"${m.kind}":{');
            push();
            addLine('"baseColorFactor":[');
            push();
            for (c in m.baseColorFactor) {
                addLine('$c,');
            }
            endList();
            addLine('],');
            pop();
            addLine('"metallicFactor":${m.metallicFactor},');
            addLine('"roughnessFactor":${m.roughnessFactor}');
            pop();
            addLine('}');
            pop();
            addLine('},');
        }
        endList();
        addLine('],');
        addLine('"meshes": [');
        push();
        for (m in meshes) {
            addLine('{');
            push();
            addLine('"primitives": [');
            push();
            for (p in m.primitives) {
                addLine('{');
                push();
                addLine('"attributes": {');
                push();
                for (attr in p.attributes) {                
                    addLine('"${attr.semantic}": ${attr.accessor.index},');
                }
                endList();
                pop();
                addLine('},');
                if (p.indices != null) {
                    addLine('"indices": ${p.indices.index},');
                }
                if (p.material != null) {
                    addLine('"material": ${p.material.index},');
                }
                endList();
                pop();
                addLine('},');    
            }
            endList();
            pop();
            addLine(']');
            pop();
            addLine('},');
        }
        endList();
        pop();
        addLine('],');
        addLine('"accessors": [');
        push();
        for (accessor in accessors) {
            addLine('{');
            push();
            addLine('"bufferView": ${accessor.bufferView.index},');
            addLine('"componentType": ${accessor.componentType},');
            addLine('"count": ${accessor.count},');
            if (accessor.max != null) {
                addLine('"max": [');
                push();
                for (m in accessor.max) {
                    addLine('$m,');
                }
                endList();
                pop();
                addLine('],');
            }
            if (accessor.min != null) {
                addLine('"min": [');
                push();
                for (m in accessor.min) {
                    addLine('$m,');
                }
                endList();
                pop();
                addLine('],');
            }
            addLine('"type": "${accessor.type}"');
            pop();
            addLine('},');
        }
        endList();
        pop();
        addLine('],');
        addLine('"bufferViews": [');
        push();
        for (bufferView in bufferViews) {
            addLine('{');
            push();
            addLine('"buffer": ${bufferView.buffer.index},');
            addLine('"byteLength": ${bufferView.byteLength},');
            addLine('"byteOffset": ${bufferView.byteOffset},');
            addLine('"target": ${bufferView.target}');
            pop();
            addLine('},');
        }
        endList();
        pop();
        addLine('],');
        addLine('"buffers": [');
        for (b in buffers) {
            addLine('{');
            push();
            addLine('"byteLength": ${b.data.length},');
            addLine('"uri": "data:application/octet-stream;base64,${haxe.crypto.Base64.encode(b.data)}"');
            pop();
            addLine('},');
        }
        endList();
        addLine(']');
        pop();
        addLine('}');
        finish();

        File.saveContent(path, buffer.toString());
    }
}