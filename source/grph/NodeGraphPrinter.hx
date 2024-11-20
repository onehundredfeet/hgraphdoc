package grph;

using Lambda;

class NodeGraphPrinter {
    public static function graphToString( g :NodeGraph ) : String {

        var sb = new StringBuf();
        sb.add( 'Graph\n' );

        for ( n in g.nodes ) {
            sb.add( '\tNode ${n.name}\n' );
            var n_parent = n.getParent();
            sb.add( '\t\tParent ${n_parent != null ? n_parent.name : 'None'}\n' );
            if ( n.properties != null ) {
                sb.add( '\t\tProperties\n' );
                for ( kv in n.properties.keyValueIterator() ) {
                    sb.add( '\t\t\tproperty ${kv.key} -> ${kv.value}\n' );
                }
                var n_outgoing = n.getOutgoingEdges().array();
                if ( n_outgoing != null && n_outgoing.length > 0 ) {
                    sb.add( '\t\tOutgoing Connections\n' );
                    for ( c in n_outgoing ) {
                        sb.add( '\t\t\tconnection "${c.name}" -> ${c.target.name}[${c.target.id}]\n' );
                    }
                }
                var n_incoming = n.getIncomingEdges().array();
                if ( n_incoming != null && n_incoming.length > 0 ) {
                    sb.add( '\t\tIncoming Connections\n' );
                    for ( c in n_incoming ) {
                        sb.add( '\t\t\tconnection "${c.name}" -> ${c.source.name}[${c.source.id}]\n' );
                    }
                }
            }
        }

        return sb.toString();
    }
}