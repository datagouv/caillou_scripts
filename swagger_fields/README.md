# Swagger fields

Le but est d'extraire les noms des champs de swaggers, pour les rapprocher des noms canoniques de l'équipe VDE (Observatoire des Démarches Essentielles).

J'ai extrait deux tableaux des swaggers d'api entreprise et api particulier, dispo ici : 

- https://github.com/datagouv/caillou_scripts/blob/main/swagger_fields_api_particulier.tsv
- https://github.com/datagouv/caillou_scripts/blob/main/swagger_fields_api_entreprise.tsv

Les sources sont les swaggers de chaque API,  dispos sur data.gouv.fr, si vous voulez aller checker "l'original" correspondant à chaque ligne :
- https://www.data.gouv.fr/dataservices/api-particulier/
- https://www.data.gouv.fr/dataservices/api-entreprise/

C'est un premier jet naïf, n'hésitez à le challenger si vous voulez voir plus de choses, dans le cadre du rapprochement avec les données canoniques de VDE.

Ce que j'imagine pour la suite :
L'étape 2 ça serait de me filer le jeu de noms canoniques, pour que j'essaye un premier rapporchement grossier à l'aide d'une LLM.
L'étape 3 ça serait de faire le même rapprochement avec les données des CERFA (source ?)