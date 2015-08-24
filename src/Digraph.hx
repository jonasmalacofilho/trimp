import vehjo.Vector;

private typedef L = vehjo.LazyLambda;

// Self-loops are possible, althought irrelevant
// Multi-(di)graphs are possible
class Digraph {

	var vertices: Map<Int, Vertex>;
	var arcs: Array<Arc>;

	public var nV: Int;
	public var nA( get_nA, never ): Int;
	function get_nA(): Int {
		return arcs.length;
	}

	public var verbose: Bool;

	public function new() {
		verbose = false;

		vertices = new Map();
		nV = 0;
		arcs = [];
	}

	// ~ O( V*A )
	public function bellmanFordRelaxation(): Void {

		var i = 0;
		while ( true ) {
			var quit = true;

			for ( v in vertices ) if ( v.lab == i ) for ( a in v.arcsFrom )
				if ( v.parent != null && ( a.w.parent == null || v.cost + a.cost < a.w.cost ) ) {
					a.w.cost = v.cost + a.cost;
					a.w.parent = v;

					a.w.graphDist = v.graphDist + a.len;
					a.w.errorDist = v.errorDist + a.w.curErrorDist;

					a.w.lab = i + 1;
					quit = false;
				}

			if ( quit ) {
				if ( verbose )
					trace( 'Bellman Ford relaxation finished early at iteration no. ' + ( i + 1 ) );
				break;
			}

			i++;
		}

	}

	public function bellmanFordHasNegativeCycles(): Bool {
		var r = false;
		for ( a in arcs )
			if ( a.v.parent != null && ( a.w.parent == null || a.v.cost + a.cost < a.w.cost ) ) {
				r = true;
				if ( verbose )
					trace( 'found a negative cycle between ' + a.v.i + ' and ' + a.w.i );
				else
					break;
			}
		return r;
	}

	public function rebuildPath( t: Vertex ): Iterable<Vertex> {
		var path = new List();
		var cur = t;
		var i = t.oldParents.length - 1;
		while ( true ) {
			while ( cur != cur.oldParents[i] ) {
				if ( cur != path.first() )
					path.push( cur );
				cur = cur.oldParents[i];
			}
			if ( cur != path.first() )
				path.push( cur );
			if ( i > 0 )
				cur = cur.oldParents[--i];
			else
				break;
		}
		return path;
	}

	public function getVertices(): Iterator<Vertex> {
		return vertices.iterator();
	}

	public function getVertex( i: Int ): Null<Vertex> {
		return vertices.get( i );
	}

	public function addVertex( i: Int, x: Float, y: Float ): Vertex {
		if ( vertices.exists( i ) )
			throw 'vertex ' + i + ' already exists';
		var v = new Vertex( i, x, y );
		vertices.set( i, v );
		nV++;
		return v;
	}

	public function getArcs(): Iterator<Arc> {
		return arcs.iterator();
	}

	public function addArc( v: Vertex, w: Vertex, cost: Float ): Arc {
		var a = new Arc( v, w, cost );
		arcs.push( a );
		return a;
	}

}

