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

...


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


# 3  -	Implementation
The implementation of this standard is implemented using SQLite databases for four equally reasons:
1.	SQLite is open source
2.	It has a spatial extension, SpatiaLite
3.	As other databases, the user can implement triggers to ensure data consistency
4.	Ample support for SQLite/Spatialite editing by GIS packages
It is true that the network standard per se can be achieved in many forms, including by the generation of regular geographic files (e.g. ShapeFiles, TabFiles, etc.) or text files with a text representation of their geographic features (e.g. Well-Known-Text, WKT). However, ensuring consistency between these elements in the face of their editing has so far not been possible outside proprietary transportation packages, and the present implementation of this standard addresses this issue.
In order for the implementation of this standard to be successful, it is necessary to map all the possible user-driven changes to the underlying data and the behavior the SQLite database needs to demonstrate in order to maintain consistency of the data. The detailed expected behavior is detailed below.
As each item in the network is edited, a series of checks and changes to other components are necessary in order to keep the network as a whole consistent. In this section we list all the possible physical (geometrical) changes to each element of the network and what behavior (consequences) we expect from each one of these changes.
Our implementation, in the form of a SQLite database, will be referred to as network from this point on.

### 3.1.1 	-  Node layer changes and expected behavior 

There are 6 possible changes envisioned for the network nodes layer, being 3 of geographic nature and 3 of data-only nature.

#### 3.1.1.1	Creating a node
A node is not to be created if not by the placement of a link (new or moved) at a position where no nodes already exists. If the user tries to create a node, the network should return an error and not perform such operation.
#### 3.1.1.2	Deleting a node
A node can only be eliminated as a consequence of all links that terminated/originated at it being eliminated. If the user tries to delete a node, the network should return an error and not perform such operation. 
#### 3.1.1.3	Moving a node
There are two possibilities for moving a node: Moving to an empty space, and moving on top of another node. 
-**If a node is moved to an empty space**
All links originated/ending at that node will have its shape altered to conform to that new node position and keep the network connected. The alteration of the link happens only by changing the Latitude and Longitude of the link extremity associated with that node.
-**If a node is moved on top of another node**
All the links that connected to the node on the bottom have their extremities switched to the node on top
The node on the bottom gets eliminated as a consequence of the behavior listed on 3.1.4 and condition listed on 3.1.2


