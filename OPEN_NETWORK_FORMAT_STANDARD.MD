The objectives of this document are twofold.  The first one is to establish a standard for transportation network interchange to facilitate the migration of transportation data between different software packages and support the development of transportation modelling tools around this standard.
The second objective is to establish an implementation of this standard in a format that ensures consistency between all components of a network and that allows for the network to be edited in as many GIS platforms as possible, including packages available as open source and those proprietary.
This document is composed of XXX sections. The first one is the enumeration of all the components of a complete network model used in strategic transportation modelling. The second section discusses the consistency required between these data components.
The third and last section discusses the implementation of this standard in one specific technology. Although not a complete implementation of the standard, this particular implementation serves as proof of concept that will be expanded as this standard is refined and finalized.


# 1  -	Transportation network components

Transportation networks are usually composed by a number of elements that that are either represented as lines (e.g. streets) or points (e.g. intersections). Although the actual composition of each particular network model varies across a large range of possibilities, this standard covers those network models that can be defined by a combination of the following 5 different elements:
1.	Network links
2.	Network nodes
3.	Turn penalties/restrictions
4.	Transit routes
5.	Transit stops

Other elements that are not part of the network model, but are closely associated with it, will be considered in this standard. Namely:
-	Traffic analysis zones
-	Traffic counts
-	Turn counts
Each one of these network components is defined by a database table composed of some mandatory and optional fields and, in most cases, by the existence of a geometric dimension associated to each entry in such database, configuring a GIS enabled data source. In turn, the requirements are derived from transportation model requirements, and are detailed next.

## 1.1	-  Network links

Network links are defined by geographic elements of type LineString (No MultiLineString allowed) and a series of mandatory fields, as well a series of other optional fields that might be required for documentation and display purposes (e.g. street names) or by specific applications (e.g. parameters for Volume-Delay functions, hazardous vehicles restrictions, etc.).

**The mandatory fields are the following**

|  Field name |                           Field Description                           |        Data Type        |
|:-----------:|:---------------------------------------------------------------------:|:-----------------------:|
| link_id     | Unique identifier                                                     | Integer (32/64 bits)    |
| a_node      | node_id of the first (topologically) node of the link                 | Integer (32/64 bits)    |
| b_node      | node_id of the last (topologically) node of the link                  | Integer (32/64 bits)    |
| direction   | Direction of flow allowed for the link (A-->B: 1, B-->A:-1, Both:0)   | Integer 8 bits          |
| capacity_ab | Modeling capacity of the link for the direction A --> B               | Float 32 bits           |
| capacity_ba | Modeling capacity of the link for the direction B --> A               | Float 32 bits           |
| speed_ab    | Modeling (Free flow) speed for the link in the A --> B direction      | Float 32 Bits           |
| speed_ab    | Modeling (Free flow) speed for the link in the B --> A direction      | Float 32 bits           |


**The optional fields may include, but are not limited to the following:**

| Field name            | Field description                                         | Data type      |
|-----------------------|-----------------------------------------------------------|----------------|
| Street name           | Cadastre name of the street                               | String         |
| Volume delay function | Type of volume delay function to be used on that link     | String         |
| Alfa_ab               | Alfa parameter for the BPR for the A->B direction of link | Float 32 bits  |
| Alfa_ba               | Alfa parameter for the BPR for the B->A direction of link | Float 32 bits  |
| Beta_ab               | Beta parameter for the BPR for the A->B direction of link | Float 32 bits  |
| Beta_ba               | Beta parameter for the BPR for the B->A direction of link | Float 32 bits  |
| Lanes_ba              | Number of lanes of the link for the direction A->B        | Integer 8 bits |
| Lanes_ba              | Number of lanes of the link for the direction B->A        | Integer 8 bits |
| ...                   | ...                                                       | ...            |
| ...                   | ...                                                       | ...            |

## 1.2	-  Network nodes

*To come*

## 1.3	-  Turn penalties

*To come*

## 1.4	-  Transit routes

*To come*

## 1.5	-  Transit stops

*To come*

# 2  -	Network components consistency

*JUST A BRIEF DISCUSSION ON WHAT IS THE RELATIONSHIP BETWEEN THE COMPONENTS OF THE NETWORK AND WHY THAT IS IMPORTANT.*



# 3  -	Implementating this standard
The network standard per se can be achieved in many forms, including by the generation of regular geographic files (e.g. ShapeFiles, TabFiles, etc.) or text files with a text representation of their geographic features (e.g. Well-Known-Text, WKT). However, dinamicaly ensuring consistency between these elements as they are individualy edited has so far not been possible outside proprietary transportation packages, and the present implementation of this standard addresses this issue.
Ensuring data consistency as each portion of the data is edited is a two part problem:
1. Knowing what to do when a certain edit is attempted by the user
2. Automatically applying the tests and consistency checks (and changes) required on one
The first part of this problem is discussed in the next section of the report, while the second part follows it.
## 3.1  -  Change behavior
In this section we present the mapping of all meaningful changes that a user can do to each part of the transportation network, doing so for each element of the transportation network.

### 3.1.1 	-  Node layer changes and expected behavior 

There are 6 possible changes envisioned for the network nodes layer, being 3 of geographic nature and 3 of data-only nature. The possible variations for each change are also discussed, and all the points where alternative behavior is conceivable are also explored.

#### 3.1.1.1	Creating a node
There are only two situations when a node is to be created:
- Placement of a link extremity (new or moved) at a position where no node already exists
- Spliting a link in the middle

In both cases a unique node ID needs to be generated for the new node, and all other node fields should be empty
An alternative behavior would be to allow the user to create nodes with no attached links. Although this would not result in inconsistent networks for traffic and transit assignments, this behavior would not be considered valid.
All other edits that result in the creation of un-connected nodes or that result in such case should result in an error that prevents such operation

#### 3.1.1.2	Deleting a node
Deleting a node is only allowed in two situations:
- No link is connected to such node (in this case, the deletion of the node should be handled automatically when no link is left connected to such node)
- When only two links are connected to such node. In this case, those two links will be merged, and a standard operation for computing the value of each field will be applied.

For simplicity, the operations are: Weighted average for all numeric fields, copying the fields from the longest link for all non-numeric fields. Length is to be recomputed in the native distance measure of distance for the projection being used.

A node can only be eliminated as a consequence of all links that terminated/originated at it being eliminated. If the user tries to delete a node, the network should return an error and not perform such operation. 

#### 3.1.1.3	Moving a node
There are two possibilities for moving a node: Moving to an empty space, and moving on top of another node.

- **If a node is moved to an empty space**
All links originated/ending at that node will have its shape altered to conform to that new node position and keep the network connected. The alteration of the link happens only by changing the Latitude and Longitude of the link extremity associated with that node.

- **If a node is moved on top of another node**
All the links that connected to the node on the bottom have their extremities switched to the node on top
The node on the bottom gets eliminated as a consequence of the behavior listed on 3.1.4 and condition listed on 3.1.2

#### 3.1.1.4	Adding a data field
No consistency check is needed other than ensuring that no repeated data field names exist

#### 3.1.1.5	Deleting a data field
If the data field whose attempted deletion is mandatory, the network should return an error and not perform such operation. Otherwise the operation can be performed.

#### 3.1.1.6	Modifying a data entry
If the field being edited is the node_id field, then all the related tables need to be edited as well (e.g. a_b and b_node in the link layer, the node_id tagged to turn restrictions and to transit stops)

### 3.1.2	Link layer changes and expected behavior 
There are 8 possible changes envisioned for the network links layer, being 5 of geographic nature and 3 of data-only nature.
#### 3.1.2.1	Deleting a link
-	Cannot be deleted if there is a transit route, traffic count, turn penalty, or turn count associated to it.
-	After deleting the link all

#### 3.1.2.2	Moving a link extremity
*To come*

#### 3.1.2.3	Re-shaping a link
*To come*

#### 3.1.2.4	Splitting a link
*To come*

#### 3.1.2.5	Merging two links
*To come*

#### 3.1.2.6	Adding data field
*To come*

#### 3.1.2.7	Deleting data field
*To come*

#### 3.1.2.8	Changing data
*To come*

### 3.1.3	Turn penalties layer changes and expected behavior
*To come*

#### 3.1.3.1	Deleting a turn penalty
*To come*

#### 3.1.3.2	Adding a turn penalty
*To come*

#### 3.1.3.3	Deleting data fields
*To come*

#### 3.1.3.4	Adding data fields
*To come*

#### 3.1.3.5	Modifying data entries
*To come*


3.4	Public transit routes changes and expected behavior 
The behavior for changes to this layer
3.5	Public transit route stops changes and expected behavior 



## 3.2  -  SQLite implementation
The implementation of this standard is performed using SQLite databases for five equally important reasons:
1.	SQLite is open source
2.	It has a spatial extension, SpatiaLite
3.	As other databases, the user can implement triggers to ensure data consistency
4.	Ample support for SQLite/Spatialite editing by GIS packages
5. Does not require infrastructure like other databases

I
This implementation choice is not, however, free of caveats. Do to technological limitations of SQLite, some of the desired behaviors identified in **3.1** cannot be implemented in SQLite, but such caveats do not impact the usefulness of this implementation or its robustness in face proper use of the tool
In order for the implementation of this standard to be successful, it is necessary to map all the possible user-driven changes to the underlying data and the behavior the SQLite database needs to demonstrate in order to maintain consistency of the data. The detailed expected behavior is detailed below.
As each item in the network is edited, a series of checks and changes to other components are necessary in order to keep the network as a whole consistent. In this section we list all the possible physical (geometrical) changes to each element of the network and what behavior (consequences) we expect from each one of these changes.
Our implementation, in the form of a SQLite database, will be referred to as network from this point on.



# 4	References

http://tfresource.org/Category:Transportation_networks

# 5	Authors

## Pedro Camargo
www.xl-optim.com
https://au.linkedin.com/in/pedrocamargo

## Andrew O'Brien
https://au.linkedin.com/in/andrew-o-brien-5a8bb486

