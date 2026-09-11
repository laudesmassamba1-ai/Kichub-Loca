-- ============================================================
-- 20260915 : Alignement statut prospect <-> historique + relances
-- ============================================================
-- Les prospects passés en "a_recontacter" via la fiche (updateCommerceStatus)
-- n'ont pas forcément de visite correspondante -> l'onglet Rappels (qui lit
-- les visites) les ignorait. On recrée les visites manquantes et on remplit
-- une date de relance par défaut quand elle est absente.

-- 1) Visites de relance manquantes pour les prospects en "a_recontacter"
INSERT INTO visites (commerce_id, agent_id, statut, date_visite, date_rappel, notes, created_at)
SELECT
    c.id,
    c.cree_par,
    'a_recontacter',
    COALESCE((SELECT MAX(v.date_visite) FROM visites v WHERE v.commerce_id = c.id), now()),
    now() + interval '7 days',
    NULL,
    now()
FROM commerces c
WHERE c.statut = 'a_recontacter'
  AND NOT EXISTS (
      SELECT 1 FROM visites v
      WHERE v.commerce_id = c.id AND v.statut = 'a_recontacter'
  );

-- 2) Date de relance par défaut (J+7) sur les visites de relance sans date
UPDATE visites
SET date_rappel = date_visite + interval '7 days'
WHERE statut = 'a_recontacter'
  AND date_rappel IS NULL;