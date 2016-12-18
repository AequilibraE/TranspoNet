-- TODO: allow arbitrary CRS
-- TODO: allow arbitrary column AND table names

-- basic network setup
-- alternatively use ogr2ogr

-- note that sqlite only recognises 5 basic column affinities (TEXT, NUMERIC, INTEGER, REAL, BLOB); more specific declarations are ignored
-- the 'INTEGER PRIMARY KEY' column is always 64-bit signed integer, AND an alias for 'ROWID'.

-- Note that manually editing the ogc_fid will corrupt the spatial index. Therefore, we leave the
-- ogc_fid alone, and have a separate link_id and node_id, for network editors who have specific
-- requirements.

-- it is recommended to use the listed edit widgets in QGIS
CREATE TABLE 'links' (
  ogc_fid INTEGER PRIMARY KEY, -- Hidden widget
  link_id INTEGER UNIQUE NOT NULL, -- Text edit widget with 'Not null' constraint
  a_node INTEGER, -- Text edit widget, with 'editable' unchecked
  b_node INTEGER, -- Text edit widget, with 'editable' unchecked
  direction INTEGER, -- Range widget, 'Editable', min=0, max=2, step=1, default=0
  capacity_ab REAL,
  capacity_ba REAL,
  speed_ab REAL,
  speed_ba REAL
);
SELECT AddGeometryColumn( 'links', 'geometry', 4326, 'LINESTRING', 'XY' );
SELECT CreateSpatialIndex( 'links' , 'geometry' );

-- it is recommended to use the listed edit widgets in QGIS
CREATE TABLE 'nodes' (
  ogc_fid INTEGER PRIMARY KEY, -- Hidden widget
  node_id INTEGER UNIQUE NOT NULL -- Text edit widget with 'Not null' constraint
);
SELECT AddGeometryColumn( 'nodes', 'geometry', 4326, 'POINT', 'XY' );
SELECT CreateSpatialIndex( 'nodes' , 'geometry' );


--
-- Triggers are grouped by the table which triggers their execution
-- 

-- Triggered by changes to links.
--

CREATE TRIGGER updated_link_geometry AFTER UPDATE OF geometry ON links
  BEGIN
  -- Update a/b_node AFTER moving a link.
  -- Note that if this TRIGGER is triggered by a node move, then the SpatialIndex may be out of date.
  -- This is why we also allow current a_node to persist.
    UPDATE links
    SET a_node = (
      SELECT node_id
      FROM nodes
      WHERE nodes.geometry = PointN(new.geometry,1) AND
      (nodes.rowid IN (
          SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
          search_frame = PointN(new.geometry,1)) OR
        nodes.node_id = new.a_node))
    WHERE links.rowid = new.rowid;
    UPDATE links
    SET b_node = (
      SELECT node_id
      FROM nodes
      WHERE nodes.geometry = PointN(links.geometry,NumPoints(links.geometry)) AND
      (nodes.rowid IN (
          SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
          search_frame = PointN(links.geometry,NumPoints(links.geometry))) OR
        nodes.node_id = new.b_node))
    WHERE links.rowid = new.rowid;
    
    -- now delete nodes which no-longer have attached links
    DELETE FROM nodes
    WHERE node_id NOT IN (
      SELECT a_node
      FROM links
      WHERE a_node is NOT NULL
      union all
      SELECT b_node
      FROM links
      WHERE b_node is NOT NULL);
  END;

CREATE TRIGGER new_link AFTER INSERT ON links
  BEGIN
  -- Update a/b_node AFTER creating a link.
    UPDATE links
    SET a_node = (
      SELECT node_id
      FROM nodes
      WHERE nodes.geometry = PointN(new.geometry,1) AND
      (nodes.rowid IN (
          SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
          search_frame = PointN(new.geometry,1)) OR
        nodes.node_id = new.a_node))
    WHERE links.rowid = new.rowid;
    UPDATE links
    SET b_node = (
      SELECT node_id
      FROM nodes
      WHERE nodes.geometry = PointN(links.geometry,NumPoints(links.geometry)) AND
      (nodes.rowid IN (
          SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
          search_frame = PointN(links.geometry,NumPoints(links.geometry))) OR
        nodes.node_id = new.b_node))
    WHERE links.rowid = new.rowid;
  END;

-- delete lonely node AFTER link deleted
CREATE TRIGGER deleted_link AFTER delete ON links
  BEGIN
    DELETE FROM nodes
    WHERE node_id NOT IN (
      SELECT a_node
      FROM links
      union all
      SELECT b_node
      FROM links);
    END;

-- when moving OR creating a link, don't allow it to duplicate an existing link.
-- TODO

-- Triggered by change of nodes
--

-- when you move a node, move attached links
CREATE TRIGGER update_node_geometry AFTER UPDATE OF geometry ON nodes
  BEGIN
    UPDATE links
    SET geometry = SetStartPoint(geometry,new.geometry)
    WHERE links.a_node = new.node_id;
    UPDATE links
    SET geometry = SetEndPoint(geometry,new.geometry)
    WHERE links.b_node = new.node_id;
  END;
  
-- when you move a node on top of another node, steal all links FROM that node, AND delete it.
-- be careful of merging the a_nodes of attached links to the new node
-- this may be better as a TRIGGER on links?
CREATE TRIGGER cannibalise_node BEFORE UPDATE OF geometry ON nodes
  WHEN
    (SELECT count(*)
    FROM nodes
    WHERE nodes.node_id != new.node_id
    AND nodes.geometry = new.geometry AND
    nodes.rowid IN (
      SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
      search_frame = new.geometry)) > 0
  BEGIN
    -- todo: change this to perform a cannibalisation instead.
    SELECT raise(ABORT, 'Cannot drop on-top of other node');
  END;
    
-- you may NOT CREATE a node on top of another node.
CREATE TRIGGER no_duplicate_node BEFORE INSERT ON nodes
  WHEN
    (SELECT count(*)
    FROM nodes
    WHERE nodes.node_id != new.node_id
    AND nodes.geometry = new.geometry AND
    nodes.rowid IN (
      SELECT rowid FROM SpatialIndex WHERE f_table_name = 'nodes' AND
      search_frame = new.geometry)) > 0
  BEGIN
    -- todo: change this to perform a cannibalisation instead.
    SELECT raise(ABORT, 'Cannot drop on-top of other node');
  END;

-- TODO: cannot CREATE node NOT attached.

-- don't delete a node, unless no attached links
CREATE TRIGGER dont_delete_node BEFORE DELETE ON nodes
  WHEN (SELECT count(*) FROM links WHERE a_node = old.node_id OR b_node = old.node_id) > 0
  BEGIN
    SELECT raise(ABORT, 'Node cannot be deleted, it still has attached links.');
  END;
  
-- don't CREATE a node, unless on a link endpoint
-- TODO
-- CREATE BEFORE WHERE spatial index AND PointN()

-- when editing node_id, UPDATE connected links
CREATE TRIGGER updated_node_id AFTER UPDATE OF node_id ON nodes
  BEGIN
    UPDATE links SET a_node = new.node_id
    WHERE links.a_node = old.node_id;
    UPDATE links SET b_node = new.node_id
    WHERE links.b_node = old.node_id;
  END;
