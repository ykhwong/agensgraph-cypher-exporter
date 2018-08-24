# AgensGraph Cypher Exporter

## INTRODUCTION
Exports the Cypher statemens directly from AgensGraph. This can be useful for a database backup.

## REQUIREMENT
* AgensGraph CLI as a client
* Perl 5

## EXPORT CYPHER
1. Run the below command to begin the export. While the graph name is set to TEMP, you may freely change the name.

```sh
  $ perl agens_export_cypher.pl --graph=TEMP
```

2. You’ll see the Cypher statements from AgensGraph.
```
DROP GRAPH IF EXISTS TEMP CASCADE;
CREATE GRAPH TEMP;
SET GRAPH_PATH=TEMP;
CREATE (:person {'name': 'Max'});
CREATE (:person {'name': 'Bill'});
CREATE (:person {'name': 'Jane'});
CREATE (:person {'name': 'Abby'});
CREATE (:person {'name': 'Hank'});
CREATE (:person {'name': 'Sophie'});
CREATE (:account {'name': 'Cayman Account', 'number': 863});
CREATE (:account {'name': 'Chase Account', 'number': 1523});
CREATE (:account {'name': 'BofA Account', 'number': 4634});
CREATE (:ssn {'number': 123456789});
CREATE (:ssn {'number': 523252364});
CREATE (:ssn {'number': 993632634});
MATCH (n1:person {'name': 'Jane'}), (n2:account {'name': 'Chase Account', 'number': 1523}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {'name': 'Abby'}), (n2:account {'name': 'Cayman Account', 'number': 863}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {'name': 'Hank'}), (n2:account {'name': 'Cayman Account', 'number': 863}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {'name': 'Bill'}), (n2:account {'name': 'BofA Account', 'number': 4634}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {'name': 'Jane'}), (n2:ssn {'number': 123456789}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {'name': 'Max'}), (n2:ssn {'number': 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {'name': 'Abby'}), (n2:ssn {'number': 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {'name': 'Sophie'}), (n2:ssn {'number': 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {'name': 'Bill'}), (n2:ssn {'number': 523252364}) CREATE (n1)-[:has_ssn]->(n2);
```

If you do not have any nodes and/or edges, then you'll get the following message.
```
DROP GRAPH IF EXISTS TEMP CASCADE;
CREATE GRAPH TEMP;
SET GRAPH_PATH=TEMP;
-- Nothing to do
```

The compatibility mode can be also changed to Neo4j.
```sh
  $ perl agens_export_cypher.pl --graph=TEMP --compt=neo4j
```

The result would be something like this:
```
CREATE (:person {name: "Max"});
CREATE (:person {name: "Bill"});
CREATE (:person {name: "Jane"});
CREATE (:person {name: "Abby"});
CREATE (:person {name: "Hank"});
CREATE (:person {name: "Sophie"});
CREATE (:account {name: "Cayman Account", "number": 863});
CREATE (:account {name: "Chase Account", "number": 1523});
CREATE (:account {name: "BofA Account", "number": 4634});
CREATE (:ssn {number: 123456789});
CREATE (:ssn {number: 523252364});
CREATE (:ssn {number: 993632634});
MATCH (n1:person {name: "Jane"}), (n2:account {name: "Chase Account", "number": 1523}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {name: "Abby"}), (n2:account {name: "Cayman Account", "number": 863}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {name: "Hank"}), (n2:account {name: "Cayman Account", "number": 863}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {name: "Bill"}), (n2:account {name: "BofA Account", "number": 4634}) CREATE (n1)-[:has_account]->(n2);
MATCH (n1:person {name: "Jane"}), (n2:ssn {number: 123456789}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {name: "Max"}), (n2:ssn {number: 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {name: "Abby"}), (n2:ssn {number: 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {name: "Sophie"}), (n2:ssn {number: 993632634}) CREATE (n1)-[:has_ssn]->(n2);
MATCH (n1:person {name: "Bill"}), (n2:ssn {number: 523252364}) CREATE (n1)-[:has_ssn]->(n2);
```

## TECHNIAL DETAILS
* '--graph=GRAPH_NAME' option must be specified because the graph repository needs to be recognized.
* Indexes will be preserved, but unique constraints will not be exported.
* VLABEL without vertexes and ELABEL without edges will not be exported. Single and multiple inheritance will not be handled.

### USAGE
```
USAGE: perl agens_export_cypher.pl [--graph=GRAPH_NAME] [--compt={agens|neo4j}] [--no-index] [--help]
   Basic parameters:
      [--compt=agens]   : Output for AgensGraph (default)
      [--compt=neo4j]   : Output for Neo4j
   Additional optional parameters for the AgensGraph integration:
      [--dbname=DBNAME] : Database name
      [--host=HOST]     : Hostname or IP
      [--port=PORT]     : Port
      [--username=USER] : Username
      [--no-password]   : No password
      [--password]      : Ask password (should happen automatically)
```
