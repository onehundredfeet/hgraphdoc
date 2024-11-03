package gdoc;

import hvector.Float2;
import hvector.Float3;
import hvector.Float4;

enum abstract AttributeSemantic(Int) to Int from Int{
	var POSITION = 0; // 3
	var NORMAL; // 3
	var TANGENT; // 3
	var TEXCOORD2_0; // 2
	var COLOR; // 4
	var TEXCOORD2_1; // 2
	var BITANGENT; // 3
}

class IndexedAttributeTriMeshF {
	static final ATTRIBUTE_DIMS = [3, 3, 3, 2, 4, 2, 3];

	public var attributes = new Array<Array<Float>>();
	public var indices = new Array<Int>();

	public inline function new(attributeSpec:Array<AttributeSemantic> = null) {
		if (attributeSpec != null) {
			for (semantic in attributeSpec) {
				this.attributes[semantic] = new Array<Float>();
			}
		}
		if (attributes[AttributeSemantic.POSITION] == null) {
			addAttribute(AttributeSemantic.POSITION);
		}
	}

    public function newBlank() {
        var mesh = new IndexedAttributeTriMeshF();
        for (i in 0... attributes.length) {
            if (attributes[i] == null)
                continue;
            mesh.addAttribute(i);
        }
        return mesh;
    }
    
	public inline function addAttribute(semantic:AttributeSemantic) {
		attributes[semantic] = new Array<Float>();
	}

	public function reserveVerts(n:Int) {
		for (attr in attributes) {
			if (attr == null)
				continue;
			var currentSize = attr.length;
			attr.resize(n);
			attr.resize(currentSize);
		}
	}

	public function reserveTris(n:Int) {
		var currentSize = indices.length;
		indices.resize(n * 3);
		indices.resize(currentSize);
	}

	public function addBlankVertex():Int {
		var idx = attributes[AttributeSemantic.POSITION].length;
		for (i in 0...attributes.length) {
			var attr = attributes[i];
			if (attr == null)
				continue;
			for (j in 0...ATTRIBUTE_DIMS[i]) {
				attr.push(0.0);
			}
		}
		return idx;
	}

	//
	// Single element setters and getters
	//
	public inline function setVertexAttributeF(semantic:AttributeSemantic, index:Int, dim:Int, value:Float) {
		final offset = ATTRIBUTE_DIMS[semantic] * index + dim;
		attributes[semantic][offset] = value;
	}

	public inline function setVertexAttributeA(semantic:AttributeSemantic, index:Int, value:Array<Float>) {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		for (i in 0...ATTRIBUTE_DIMS[semantic]) {
			attributes[semantic][offset + i] = value[i];
		}
	}

	public inline function setVertexAttributeF2(semantic:AttributeSemantic, index:Int, value:Float2) {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		attributes[semantic][offset] = value.x;
		attributes[semantic][offset + 1] = value.y;
	}

	public inline function setVertexAttributeF3(semantic:AttributeSemantic, index:Int, value:Float3) {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		attributes[semantic][offset] = value.x;
		attributes[semantic][offset + 1] = value.y;
		attributes[semantic][offset + 2] = value.z;
	}

	public inline function setVertexAttributeF4(semantic:AttributeSemantic, index:Int, value:Float4) {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		attributes[semantic][offset] = value.x;
		attributes[semantic][offset + 1] = value.y;
		attributes[semantic][offset + 2] = value.z;
		attributes[semantic][offset + 3] = value.w;
	}

	public inline function getVertexAttributeF(semantic:AttributeSemantic, index:Int, dim:Int):Float {
		final offset = ATTRIBUTE_DIMS[semantic] * index + dim;
		return attributes[semantic][offset];
	}

	public inline function getVertexAttributeA(semantic:AttributeSemantic, index:Int):Array<Float> {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		var result = new Array<Float>();
		for (i in 0...ATTRIBUTE_DIMS[semantic]) {
			result.push(attributes[semantic][offset + i]);
		}
		return result;
	}

	public inline function getVertexAttributeF2(semantic:AttributeSemantic, index:Int):Float2 {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		return new Float2(attributes[semantic][offset], attributes[semantic][offset + 1]);
	}

	public inline function getVertexAttributeF3(semantic:AttributeSemantic, index:Int):Float3 {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		return new Float3(attributes[semantic][offset], attributes[semantic][offset + 1], attributes[semantic][offset + 2]);
	}

	public inline function getVertexAttributeF4(semantic:AttributeSemantic, index:Int):Float4 {
		final offset = ATTRIBUTE_DIMS[semantic] * index;
		return new Float4(attributes[semantic][offset], attributes[semantic][offset + 1], attributes[semantic][offset + 2], attributes[semantic][offset + 3]);
	}

	// Full array setters and getters
	public inline function setVertexAttributesF(semantic:AttributeSemantic, values:Array<Float>) {
		attributes[semantic] = values;
	}

	public inline function getVertexAttributesF(semantic:AttributeSemantic):Array<Float> {
		return attributes[semantic];
	}

	// triangles
	public inline function addTriangle(a:Int, b:Int, c:Int) {
		indices.push(a);
		indices.push(b);
		indices.push(c);
	}

	public inline function addTriangleA(abc:Array<Int>) {
		indices.push(abc[0]);
		indices.push(abc[1]);
		indices.push(abc[2]);
	}

	public inline function addTriangles(tris:Array<Int>) {
		for (tri in tris)
			indices.push(tri);
	}

	public inline function getVertCount() : Int {
		return Std.int(attributes[POSITION].length / ATTRIBUTE_DIMS[POSITION]);
	}
	public inline function getTriCount() : Int {
		return Std.int( indices.length / 3);
	}
}

typedef IndexedAttributeTriMesh = IndexedAttributeTriMeshF;

enum abstract AttributeFormat(Int) to Int {
	var FLOAT;
	var HALF;
	var DOUBLE;
	var INT_8;
	var INT_16;
	var INT_32;
	var UINT_8 = 0x10 | INT_8;
	var UINT_16 = 0x10 | INT_16;
	var UINT_32 = 0x10 | INT_32;
	var UINT_8_NORM = 0x20 | INT_8;
	var UINT_16_NORM = 0x20 | INT_16;
	var UINT_32_NORM = 0x20 | INT_32;

	public inline function isSigned() {
		return this & 0x10 == 0;
	}

	public inline function isNormalized() {
		return this & 0x20 != 0;
	}
}

// class IndexedAttributeTriMeshQuantized {}
