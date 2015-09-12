recipe create_repository
  + mkdir source/{{proj}}.git
  + cd source/{{proj}}.git && git init --bare
  ! cd {{proj}} && git init && git add * && git commit -m "initial import"
  ! cd {{proj}} && git remote add origin {{git_host}}:source/{{proj}}.git
  ! cd {{proj}} && git push -u origin master
