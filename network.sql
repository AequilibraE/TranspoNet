-- basic network setup
-- alternatively use ogr2ogr
-- note that sqlite only recognises 5 basic column affinities (TEXT, NUMERIC, INTEGER, REAL, BLOB); more specific declarations are ignored
-- the 'INTEGER PRIMARY KEY' column is always 64-bit signed integer, and an alias for 'ROWID'.
CREATE TABLE 'links' (
  link_id INTEGER PRIMARY KEY,
  a_node INTEGER,
  b_node INTEGER,
  direction INTEGER,
  capacity_ab REAL,
  capacity_ba REAL,
  speed_ab REAL,
  speed_ba REAL
);
SELECT AddGeometryColumn( 'links', 'geometry', 4326, 'LINESTRING', 'XY' );
SELECT CreateSpatialIndex( 'links' , 'geometry' );

CREATE TABLE 'nodes' (
  node_id INTEGER PRIMARY KEY
);
SELECT AddGeometryColumn( 'nodes', 'geometry', 4326, 'POINT', 'XY' );
SELECT CreateSpatialIndex( 'nodes' , 'geometry' );


--
-- Triggers are grouped by the table which triggers their execution
-- 

-- Triggered by changes to links.
--

-- Update a/b_node after creating or moving a link.
-- Note that if this trigger is triggered by a node move, then the SpatialIndex may be out of date.
-- This is why we also allow current a_node to persist.
create trigger update_ab_nodes after update of geometry on links
  begin
    update links
    set a_node = (
      select node_id
      from nodes
      where nodes.geometry = PointN(new.geometry,1) and
      (nodes.rowid in (
          select rowid from SpatialIndex where f_table_name = 'nodes' and
          search_frame = PointN(new.geometry,1)) or
        nodes.node_id = new.a_node))
    where links.rowid = new.rowid;
    update links
    set b_node = (
      select node_id
      from nodes
      where nodes.geometry = PointN(links.geometry,NumPoints(links.geometry)) and
      (nodes.rowid in (
          select rowid from SpatialIndex where f_table_name = 'nodes' and
          search_frame = PointN(links.geometry,NumPoints(links.geometry))) or
        nodes.node_id = new.b_node))
    where links.rowid = new.rowid;
  end;

create trigger insert_ab_nodes after insert on links
  begin
    update links
    set a_node = (
      select node_id
      from nodes
      where nodes.geometry = PointN(new.geometry,1) and
      (nodes.rowid in (
          select rowid from SpatialIndex where f_table_name = 'nodes' and
          search_frame = PointN(new.geometry,1)) or
        nodes.node_id = new.a_node))
    where links.rowid = new.rowid;
    update links
    set b_node = (
      select node_id
      from nodes
      where nodes.geometry = PointN(links.geometry,NumPoints(links.geometry)) and
      (nodes.rowid in (
          select rowid from SpatialIndex where f_table_name = 'nodes' and
          search_frame = PointN(links.geometry,NumPoints(links.geometry))) or
        nodes.node_id = new.b_node))
    where links.rowid = new.rowid;
  end;

-- delete lonely node after link deleted
-- todo

-- prevent deletion of mandatory fields not possible with sqlite: no trigger before alter table

-- when moving or creating a link, don't allow it to duplicate an existing link.

-- Triggered by change of nodes
--

-- when you move a node, move attached links
create trigger update_ab_links after update of geometry on nodes
  begin
    update links
    set geometry = SetStartPoint(geometry,new.geometry)
    where links.a_node = new.node_id;
    update links
    set geometry = SetEndPoint(geometry,new.geometry)
    where links.b_node = new.node_id;
  end;
  
-- when you move a node on top of another node, steal all links from that node, and delete it.
-- be careful of merging the a_nodes of attached links to the new node
-- this may be better as a trigger on links?
create trigger cannibalise_node before update of geometry on nodes
  when 
    (select count(*)
    from nodes
    where nodes.node_id != new.node_id
    and nodes.geometry = new.geometry and
    nodes.rowid in (
      select rowid from SpatialIndex where f_table_name = 'nodes' and
      search_frame = new.geometry)) > 0
  begin
    -- todo: change this to perform a cannibalisation instead.
    select raise(ABORT, 'Cannot drop on-top of other node');
  end;
    
-- you may not create a node on top of another node.
create trigger no_duplicate_node before insert on nodes
  when 
    (select count(*)
    from nodes
    where nodes.node_id != new.node_id
    and nodes.geometry = new.geometry and
    nodes.rowid in (
      select rowid from SpatialIndex where f_table_name = 'nodes' and
      search_frame = new.geometry)) > 0
  begin
    -- todo: change this to perform a cannibalisation instead.
    select raise(ABORT, 'Cannot drop on-top of other node');
  end;

-- don't delete a node, unless no attached links
-- todo: consider moving the when clause before begin.
create trigger dont_delete_node before delete on nodes
  when (select count(*) from links where a_node = old.node_id or b_node = old.node_id) > 0
  begin
    select raise(ABORT, 'Node cannot be deleted, it still has attached links.');
  end;
  
-- don't create a node, unless on a link endpoint
-- TODO
-- create before where spatial index and PointN()

-- when editing node_id, update connected links


-- when deleting a node, set attached links' a/b_node to nil
-- Note: this behaviour not preferred; prevent delete instead.
/*
create trigger delete_a_links after delete on nodes
  begin
    update links
    set a_node = null
    where links.a_node = old.node_id;
  end;
create trigger delete_b_links after delete on nodes
  begin
    update links
    set b_node = null
    where links.b_node = old.node_id;
  end;
*/
