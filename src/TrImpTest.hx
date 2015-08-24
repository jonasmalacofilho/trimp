import vehjo.Vector;
private typedef L = vehjo.LazyLambda;

class TrImpTest extends vehjo.unit.TestCase {

	static function main() {
		var r = new vehjo.unit.TestRunner();
		r.add( new TrImpTest() );
		r.run();
	}

	function testPathRebuilding1() {
		var dg = digraph1();
		L.iter( L.lazy( dg.getVertices() ), $x.clear() );

		// path: 0-1-2, 2-3-4, 4-4
		// 0-1-2
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 0 ).parent = dg.getVertex( 0 );
		dg.getVertex( 1 ).parent = dg.getVertex( 0 );
		dg.getVertex( 2 ).parent = dg.getVertex( 1 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 2-3-4
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 2 ).parent = dg.getVertex( 2 );
		dg.getVertex( 3 ).parent = dg.getVertex( 2 );
		dg.getVertex( 4 ).parent = dg.getVertex( 3 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 4-4
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 4 ).parent = dg.getVertex( 4 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );

		var path = dg.rebuildPath( dg.getVertex( 4 ) );
		assertEquals( '0-1-2-3-4', L.join( L.map( path, $x.i ), '-' ) );

		// path2: 0-1-2, 2-3-4, 4-4, 4-3-2-1, 1-2-3, 3-2, 2-3, 3-4, 4-4
		// (...)
		// 4-3-2-1
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 4 ).parent = dg.getVertex( 4 );
		dg.getVertex( 3 ).parent = dg.getVertex( 4 );
		dg.getVertex( 2 ).parent = dg.getVertex( 3 );
		dg.getVertex( 1 ).parent = dg.getVertex( 2 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 1-2-3
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 1 ).parent = dg.getVertex( 1 );
		dg.getVertex( 2 ).parent = dg.getVertex( 1 );
		dg.getVertex( 3 ).parent = dg.getVertex( 2 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 3-2
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 3 ).parent = dg.getVertex( 3 );
		dg.getVertex( 2 ).parent = dg.getVertex( 3 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 2-3
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 2 ).parent = dg.getVertex( 2 );
		dg.getVertex( 3 ).parent = dg.getVertex( 2 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 3-4
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 3 ).parent = dg.getVertex( 3 );
		dg.getVertex( 4 ).parent = dg.getVertex( 3 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );
		// 4-4
		L.iter( L.lazy( dg.getVertices() ), $x.parent = $x );
		dg.getVertex( 4 ).parent = dg.getVertex( 4 );
		L.iter( L.lazy( dg.getVertices() ), $x.oldParents.push( $x.parent ) );

		var path2 = dg.rebuildPath( dg.getVertex( 4 ) );
		assertEquals( '0-1-2-3-4-3-2-1-2-3-2-3-4', L.join( L.map( path2, $x.i ), '-' ) );
	}

	function testTrImp1() {
		#if debug
		trace( 'testTrImp1' );
		#end

		var dg = digraph1();
		var ref = [ dg.getVertex( 0 ).sum( new Vector( .02, -.01 ) ),
			dg.getVertex( 2 ).sum( new Vector( -.01, .04 ) ),
			dg.getVertex( 4 ).sum( new Vector( .01, .02 ) ) ];

		#if debug
		TrImp._callback = function ( i ) {
			var s = i + ':\n';
			for ( v in dg.getVertices() ) {
				var allParents = v.oldParents.concat( [ v.parent ] );
				s += '[' + v.i + ',' + v.cost + ',' + L.join( L.map( allParents, $x != null ? $x.i : -1 ), ',' ) + ']\n';
			}
			trace( s );
		}
		#end

		var c_1_0 = new TrImp( ref, dg, 1., 0. );
		assertEquals( '0-1-2-3-4', L.join( L.map( c_1_0.path, $x.i ), '-' ) );

		#if debug
		TrImp._callback = null;
		#end
	}

	function testNullParents() {
		#if debug
		trace( 'testNullParents' );
		#end

		var dg = digraph1();
		var ref = [ dg.getVertex( 0 ).sum( new Vector( .02, -.01 ) ),
			dg.getVertex( 2 ).sum( new Vector( -.01, .04 ) ),
			dg.getVertex( 4 ).sum( new Vector( .01, .02 ) ) ];

		var c_all_none = new TrImp( ref, dg, 1., 0., null, [] );
		assertEquals( null, c_all_none.path );

		// bug fix for [01c1c7c556]
		var c_none_all = new TrImp( ref, dg, 1., 0., [], null );
		assertEquals( null, c_none_all.path );
	}

	/**
		A linear graph:
		    0         2         4
		    X====X====X====X====X
		         1         3
	**/
	function digraph1(): Digraph {
		var dg = new Digraph();
		var vs = [ dg.addVertex( 0, 0., 0. ),
			dg.addVertex( 1, 1., 1. ),
			dg.addVertex( 2, 2., 2. ),
			dg.addVertex( 3, 3., 3. ),
			dg.addVertex( 4, 4., 4. ) ];
		dg.addArc( vs[0], vs[1], 0. ); dg.addArc( vs[1], vs[0], 0. );
		dg.addArc( vs[1], vs[2], 0. ); dg.addArc( vs[2], vs[1], 0. );
		dg.addArc( vs[2], vs[3], 0. ); dg.addArc( vs[3], vs[2], 0. );
		dg.addArc( vs[3], vs[4], 0. ); dg.addArc( vs[4], vs[3], 0. );
		return dg;
	}

}

