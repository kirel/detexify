# Migration to postgres

    curl l:5984/detexify/_all_docs?include_docs=true > all_docs.json

    jq -c '.rows[] | select( .doc.data ) | {key: .doc.id, strokes: [.doc.data[] | [.[] | [.x,.y,.t]]] }' < all_docs.json > detexify.json

    ruby migrate_postgres.rb

    pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --no-owner --no-acl detexify | gzip > detexify.sql.gz

    gunzip -c detexify.sql.gz | psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER detexify

    gunzip -c detexify-partly-clean.sql.gz | heroku pg:psql --app sample-tool DATABASE_URL
