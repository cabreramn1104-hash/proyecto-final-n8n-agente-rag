-- Proyecto Final · Vector Store en Supabase (pgvector)
-- Ejecutar en Supabase → SQL Editor. Dimensión 768 = nomic-embed-text (Ollama).
-- Si cambiás el modelo de embeddings, cambiá la dimensión y reindexá todo.

create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,            -- texto del fragmento
  metadata jsonb,          -- { "archivo": "manual-vpn.txt", "indexado_el": "2026-11-09", ... }
  embedding vector(768)
);

-- Función que usa el nodo Supabase Vector Store de n8n (queryName = match_documents)
create or replace function match_documents (
  query_embedding vector(768),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select id, content, metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Índice para que la búsqueda siga siendo rápida cuando crezcan los manuales
create index if not exists documents_embedding_idx
  on documents using hnsw (embedding vector_cosine_ops);

-- Para reindexar desde cero (antes de usar "Reindexar manuales"):
-- truncate table documents;
