from pyspatialite import dbapi2 as db

network_name = 'D:/Pedro/trash/network.sqlite'
queries = 'D:/Pedro/SRC/TranspoNet/scripts/create-empty-network.sql'

def create_tranponet_from_queries(network_name, queries):
    conn = db.connect(network_name)
    curr = conn.cursor()
    # Reads all commands
    sql_file = open(queries, 'r')
    query_list = sql_file.read()
    sql_file.close()
    # Split individual commands
    sql_commands_list = query_list.split('#')
    # Run one query/command at a time
    for cmd in sql_commands_list:
        try:
           curr.execute(cmd)
        except:
            print "\n\n\nQuery error:"
            print cmd
    conn.commit()
    conn.close()

create_tranponet_from_queries(network_name, queries)