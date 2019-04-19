set -x
mvn -Dexec.executable='echo' -Dexec.args='${project.artifactId}' exec:exec -q
mvn help:active-profiles