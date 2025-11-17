# Livrables attendus 
## Sur linear : https://linear.app/pole-api/view/tickets-termines-pour-livrable-malt-7ba5f7196fd9a
## Changer le filtre "'Completed date' after 'Dec 2024'" pour avoir la bonne date
## Exporter en CSV, ouvrir dans libreoffice
## Garder les colonnes : Team, Titre, projet, completed
## Replace by nothing this regexp to format the date : T\d\d:\d\d:\d\d.\d\d\dZ
## Ajouter des bordures aux cases


# Traces des évolutions
## Dans une console irb, run this

date_begin = '2025-07-16'
date_end = '2025-11-17'

repos = {
  'Datapass' => 'https://github.com/etalab/data_pass',
  'Datapass legacy' => 'https://github.com/betagouv/datapass',
  'Formulaire QF' => 'https://github.com/etalab/formulaire-qf',
  'SIADE (API particulier & API entreprise)' => 'https://github.com/etalab/siade',
  'Admin API entreprise' => 'https://github.com/etalab/admin_api_entreprise',
  'Ansible (infra)' => 'https://github.com/etalab/very_ansible',
  'Pass Marché' => 'https://github.com/datagouv/voie_rapide',
  'HubEE v2' => 'https://github.com/datagouv/hubee',
  # Simplifions ? udata-front-kit & DAGs
}

def build_prs_url(repo_url, date_begin, date_end)
  "#{repo_url}/pulls?q=is%3Apr+draft%3Afalse+created%3A#{date_begin}..#{date_end}"
end

def build_prs_link(repo_name, repo_url, date_begin, date_end)
  "Les pull requests de #{repo_name} :\n#{build_prs_url(repo_url, date_begin, date_end)}\n"
end

def build_prs_links(repos, date_begin, date_end)
  repos.map do |repo_name, repo_url|
    build_prs_link(repo_name, repo_url, date_begin, date_end)
  end.join("\n")
end

puts build_prs_links(repos, date_begin, date_end)









