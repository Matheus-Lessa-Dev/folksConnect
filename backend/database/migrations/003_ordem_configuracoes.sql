-- O schema legado permitia vários checklists sem ordem. Atribui uma ordem
-- determinística sem trocar os identificadores nem os nomes existentes.
WITH ordenados AS (
    SELECT id_checklist, row_number() OVER (ORDER BY ordem, id_checklist) - 1 AS posicao
    FROM checklists
)
UPDATE checklists c SET ordem = o.posicao FROM ordenados o WHERE c.id_checklist = o.id_checklist;

ALTER TABLE etapas_kanban ADD CONSTRAINT uq_kanban_ordem UNIQUE (ordem) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE etapas_funil ADD CONSTRAINT uq_funil_ordem UNIQUE (ordem) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE checklists ADD CONSTRAINT uq_checklist_ordem UNIQUE (ordem) DEFERRABLE INITIALLY DEFERRED;
