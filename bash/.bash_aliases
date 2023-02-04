unalias -a

ipsec ()
{
  [ ${#} -ne 1 ] && printf "ipsec needs 1 parameter\n" && return 1
  case "${1}" in
    'up') if command ip route show dev eno1 | grep -E '172.22.68.' > /dev/null
          then
            printf '\nRetrait des proxies Parisiens\n'
            sudo bash -c "printf '#Acquire::http::Proxy \"http://127.0.0.1:3128\";\n#Acquire::https::Proxy \"http://127.0.0.1:3128\";\n' > /etc/apt/apt.conf.d/99proxy"
            printf 'function FindProxyForURL(url, host){\n  return "DIRECT";\n}\n' > "${HOME}"/.proxy.pac
            chmod 0644 "${HOME}"/.proxy.pac
            printf '\nRetrait du DNS menteur\n'
            sudo bash -c "printf '# Generated by NetworkManager\nsearch edcs.fr\nnameserver 127.0.0.53\n' > /etc/resolv.conf"
            printf '\nRetrait des clés chargées dans l'"'"'agent SSH\n'
            ssh-add -e /usr/lib/in_p11/libidop11.so
            printf '\nAjout des clés de la carte dans l'"'"'agent SSH\n'
            ssh-add -s /usr/lib/in_p11/libidop11.so
            printf '\nArret du service Strongswan\n'
            sudo systemctl stop strongswan
            printf '\nPassage du MTU a 1500\n'
            sudo ifconfig wlo1 mtu 1500 up
          else
            printf 'Ajout des proxies parisiens\n'
            sudo bash -c "printf 'Acquire {\n  http {\n    Proxy \"http://ha1-cspx-astreinte.sen.centre-serveur.i2:8380\";\n    Timeout \"120\";\n    Pipeline-Depth \"5\";\n\n    No-Cache \"false\";\n    Max-Age \"86400\";        // 1 Day age on index files\n    No-Store \"false\";       // Prevent the cache from storing archives\n  }\n};\n' > /etc/apt/apt.conf.d/99proxy"
            printf 'function FindProxyForURL(url, host){\n  if (dnsDomainIs(host, "gitlab.edcs.fr")) {return "SOCKS5 localhost:3128";}\n  if (dnsDomainIs(host, ".edcs.fr")) {return "DIRECT";}\n  if (shExpMatch(host, "172.22.0.0/16")) {return "DIRECT";}\n  return "PROXY ha1-cspx-astreinte.sen.centre-serveur.i2:8380";\n}\n' > "${HOME}"/.proxy.pac
            chmod 0644 "${HOME}"/.proxy.pac
            printf 'Démarrage du service Strongswan\n'
            sudo systemctl restart strongswan
            printf '\nEntrez votre code PIN de carte agent aux 2 demandes de mot de passe qui vont suivre\n\nDéblocage de la carte agent pour le tunnel\n'
            sudo swanctl --load-creds 1> /dev/null
            if ! sudo swanctl --initiate --child safita_ipsec_child 1> /dev/null
            then
              printf '\nProblème lors de l'"'"'établissement du tunnel - ABANDON\n'
              sudo systemctl stop strongswan
              return 1
            fi
            printf '\nRetrait des clés chargées dans l'"'"'agent SSH\n'
            ssh-add -e /usr/lib/in_p11/libidop11.so
            printf '\nAjout des clés de la carte dans l'"'"'agent SSH\n'
            ssh-add -s /usr/lib/in_p11/libidop11.so
            set -- '1400'
            printf '\nPassage du MTU a %s\n' "${1}"
            sudo ifconfig wlo1 mtu "${1}" up
          fi
          sudo bash -c "printf '[Service]\nEnvironment=\"HTTP_PROXY=http://ha1-cspx-astreinte.sen.centre-serveur.i2:8380\"\nEnvironment=\"HTTPS_PROXY=http://ha1-cspx-astreinte.sen.centre-serveur.i2:8380\"\n' > /etc/systemd/system/docker.service.d/service-env.conf"
          sudo bash -c "printf 'export http_proxy=\"http://ha1-cspx-astreinte.sen.centre-serveur.i2:8380\"\nexport https_proxy=\"http://ha1-cspx-astreinte.sen.centre-serveur.i2:8380\"\n' > /etc/default/docker"
          git config --global https.proxy ha1-cspx-astreinte.sen.centre-serveur.i2:8380
          git config --global http.proxy ha1-cspx-astreinte.sen.centre-serveur.i2:8380
          ;;
    'down') if ! command ip route show dev eno1 | grep -E '172.22.68.' > /dev/null
            then
              printf 'Disconnect through IPSEC\n'
              sudo swanctl -t --ike safita_ipsec 1>/dev/null

              pkill -f proxycs
            fi

            printf '\nRetrait des proxies Parisiens\n'
            sudo bash -c "printf '#Acquire::http::Proxy \"http://127.0.0.1:3128\";\n#Acquire::https::Proxy \"http://127.0.0.1:3128\";\n' > /etc/apt/apt.conf.d/99proxy"
            printf 'function FindProxyForURL(url, host){\n  return "DIRECT";\n}\n' > "${HOME}"/.proxy.pac
            chmod 0644 "${HOME}"/.proxy.pac
            printf '\nRetrait du DNS menteur\n'
            sudo bash -c "printf '# Generated by NetworkManager\nsearch edcs.fr\nnameserver 127.0.0.53\n' > /etc/resolv.conf"
            printf '\nRetrait des clés chargées dans l'"'"'agent SSH\n'
            ssh-add -e /usr/lib/in_p11/libidop11.so
            printf '\nArret du service Strongswan\n'
            sudo systemctl stop strongswan
            printf '\nPassage du MTU a 1500\n'
            sudo ifconfig wlo1 mtu 1500 up
            sudo rm -f /etc/systemd/system/docker.service.d/service-env.conf
            sudo bash -c ': > /etc/default/docker'
            git config --global --unset https.proxy
            git config --global --unset http.proxy
            ;;
    *) ssh ptomas@bdx.bastion"${1}".edcs.fr ;;
  esac
}

mario () {
  command vim -u /etc/vim/vimrc -N -c "execute \"Mario\" | tabonly | set nowrap | normal! G | echo \"Poisson d'avril ! Quitter = Q, Jouer = Haut, Gauche, Droite et mettre la police du terminal à 6"
}

tbm () {
  while :
  do
    local D B1 B1b B2 B2b T1 T1b T2 T2b IN
    D=$(printf "%(%A %d %B %Y %H:%M:%S)T")
    B1="$(command curl -x ha1-cspx-astreinte.sen.centre-serveur.i2:8380 -L https://ws.infotbm.com/ws/1.0/get-realtime-pass/3049/03 2> /dev/null | command jq -r '.destinations[][] | "\(.waittime_text) \(.destination_name) \(.arrival_theorique)"')"
    B1b="$(printf "%s\n" "${B1}" | command grep -E "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    [[ ${#B1b} -gt 0 ]] && B1b="${B1b}\n"
    B1="$(printf "%s\n" "${B1}" | command grep -vE "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    B2="$(command curl -x ha1-cspx-astreinte.sen.centre-serveur.i2:8380 -L https://ws.infotbm.com/ws/1.0/get-realtime-pass/112/71 2> /dev/null | command jq -r '.destinations[][] | "\(.waittime_text) \(.destination_name) \(.arrival_theorique)"')"
    B2b="$(printf "%s\n" "${B2}" | command grep -E "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    [[ ${#B2b} -gt 0 ]] && B2b="${B2b}\n"
    B2="$(printf "%s\n" "${B2}" | command grep -vE "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    T1="$(command curl -x ha1-cspx-astreinte.sen.centre-serveur.i2:8380 -L https://ws.infotbm.com/ws/1.0/get-realtime-pass/3696/A 2> /dev/null | command jq -r '.destinations[][] | "\(.waittime_text) \(.destination_name) \(.arrival_theorique)"')"
    T1b="$(printf "%s\n" "${T1}" | command grep -E "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    [[ ${#T1b} -gt 0 ]] && T1b="${T1b}\n"
    T1="$(printf "%s\n" "${T1}" | command grep -vE "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    T2="$(command curl -x ha1-cspx-astreinte.sen.centre-serveur.i2:8380 -L https://ws.infotbm.com/ws/1.0/get-realtime-pass/3715/A 2> /dev/null | command jq -r '.destinations[][] | "\(.waittime_text) \(.destination_name) \(.arrival_theorique)"')"
    T2b="$(printf "%s\n" "${T2}" | command grep -E "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    [[ ${#T2b} -gt 0 ]] && T2b="${T2b}\n"
    T2="$(printf "%s\n" "${T2}" | command grep -vE "heure" | command sort -n | command uniq | command sed -e "s/\([[:alpha:]]\)\([[:alpha:]]*\)/\1\L\2/g; s/:[[:digit:]]\{2\}$//; s/[[:digit:]]\{4,\}-[[:digit:]]\{2\}-[[:digit:]]\{2\} //")"
    clear
    printf "${D}\n\n🚍 \033[1;37;1;44m 3 \033[0m Collège Hastignan\n${B1}\n${B1b}\n🚍 \033[1;37;1;42m 71 \033[0m Cerema\n${B2}\n${B2b}\n🚇 \033[1;37m\033[1;48;5;198m A \033[0m Palmer\n${T1}\n${T1b}\n🚇 \033[1;37m\033[1;48;5;198m A \033[0m Place Du Palais\n${T2}\n${T2b}\nPress Q to quit"
    read -s -n 1 -t 1 IN <&1
    [[ ${IN} == "q" ]] && break
  done
  clear
}

colors () { command curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/ | bash; }

ls () { command ls --color "${@}"; }
grep () { command grep --color "${@}"; }
diff () { command diff -u --color "${@}"; }
ag () { command ag -t --hidden --color --multiline --numbers --pager "less -R" "${@}"; }
agi () { command ag --hidden --color --multiline --numbers --pager "less -R" --ignore "${@}"; }
tree () { command tree -C "${@}"; }
watch () { printf '\033[s\033[?1049h\033[?7l\033[?25l\033[H'; stty -echo; while :; do printf '\033[2J\033[HPress Q to quit\n\n'; eval "${@}"; unset IN; read -r -n 1 -t 1 IN; [[ ${IN} == q ]] && break; done; printf '\033[?7h\033[?25h\033[2J\033[?1049l\033[u'; stty echo; }
ps () { command ps -a -x "${@}"; }
rm () { command rm -i -r -v "${@}"; }
cp () { command cp -i -r -v "${@}"; }
mv () { command mv -i -n -v "${@}"; }
ln () { command ln -i -v "${@}"; }
rl () { command readlink -m "${@}"; }
mkdir () { command mkdir -p -v "${@}"; }
alias sudo='sudo '
cal () { command ncal -w -b -M "${@}"; }
vi () { command vim "${@}"; }
ip () { command hostname -I "${@}"; }
less () { command less -R "${@}"; }

set 1 2 3 4
while [ "${*}" ]
do
  alias ."$(printf '.%0.s' "${@}")"='cd '"$(printf '../%0.s' "${@}")"
  shift
done

extract () {
  # Not enough args
  if [[ ${#} -lt 1 ]]; then
    echo "Usage: extract <path/file_name>"\
      ".<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    return 1
  fi

  # File not found
  if [[ ! -e ${1} ]]; then
    echo -e "File does not exist!"
    return 2
  fi

  # Extracted dir already exists
  local DIR="${1}_extracted"
  if [[ -d ${DIR} ]]; then
    echo -e "${DIR} already exists. Can't extract in a safe destination."
    return 3
  fi

  mkdir "${DIR}"
  local FILE="$(command basename "${1}")"

  case "${FILE##*.}" in
    tar)
      echo -e "Extracting ${1} to ${DIR}: (uncompressed tar)"
      command tar xvf "${1}" -C "${DIR}" ;;
    gz)
      echo -e "Extracting ${1} to ${DIR}: (gip compressed tar)"
      command tar xvfz "${1}" -C "${DIR}" ;;
    tgz)
      echo -e "Extracting ${1} to ${DIR}: (gip compressed tar)"
      command tar xvfz "${1}" -C "${DIR}" ;;
    xz)
      echo -e "Extracting  ${1} to ${DIR}: (gip compressed tar)"
      command tar xvf -J "${1}" -C "${DIR}" ;;
    bz2)
      echo -e "Extracting ${1} to ${DIR}: (bzip compressed tar)"
      command tar xvfj "${1}" -C "${DIR}" ;;
    tbz2)
      echo -e "Extracting ${1} to ${DIR}: (tbz2 compressed tar)"
      command tar xvjf "${1}" -C "${DIR}" ;;
    zip)
      echo -e "Extracting ${1} to ${DIR}: (zip compressed file)"
      command unzip "${1}" -d "${DIR}" ;;
    lzma)
      echo -e "Extracting ${1} : (lzma compressed file)"
      command unlzma "${1}" ;;
    rar)
      echo -e "Extracting ${1} to ${DIR}: (rar compressed file)"
      command unrar x "${1}" "${DIR}" ;;
    7z)
      echo -e  "Extracting ${1} to ${DIR}: (7zip compressed file)"
      command 7za e "${1}" -o "${DIR}" ;;
    xz)
      echo -e  "Extracting ${1} : (xz compressed file)"
      command unxz  "${1}" ;;
    exe)
      command cabextract "${1}" ;;
    *)
      echo -e "Unknown format"
      return ;;
  esac
}

git ()
{
  local git_dir
  git_dir="$(command git rev-parse --git-dir 2> /dev/null)"
  readonly git_dir
  if command git rev-parse --git-dir > /dev/null 2>&1
  then
    if [[ ${1} == push ]]
    then
      if [[ -x ${git_dir}/hooks/pre-push ]]
      then
        exec "${git_dir}/hooks/pre-push" || return 1
      fi
    fi
    command git "${@}" || return 1
    if [[ ${1} == push ]]
    then
      if [[ -x ${git_dir}/hooks/post-push ]]
      then
        exec "${git_dir}/hooks/post-push" || return 1
      fi
    fi
  else
    return 1
  fi
}

git config --global --replace-all alias.ranking "!bash -c \"
git-ranking () {
  if [[ \${#} -eq 0 ]]; then
    git ls-files \
      | command xargs -n1 \git blame --line-porcelain | command sed -n 's/^author //p' \
      | command sort -f | command uniq -i -c | command sort -n -r
  else
    git blame --line-porcelain \$* | command sed -n 's/^author //p' | command sort -f \
      | command uniq -i -c | command sort -n -r
  fi
  echo
  command github-linguist \$*
}
git-ranking\""

git config --global --replace-all alias.root 'rev-parse --show-toplevel'
git config --global --replace-all alias.uncommit 'reset --soft HEAD~1'
git config --global --replace-all alias.unpushed 'log --oneline origin/master..master'

ga () { git add "${@}"; }
gaa () { git add -A "${@}"; }
gam () { git add -A && git commit -m "${@}"; }
gamp () { git add -A && git commit -m "$@" && git pull && git push; }
gb () { git branch "${@}"; }
gc () { git clone "${@}"; }
gd () { tig status "${@}"; }
gg () { git ranking "${@}"; }
gh () { git checkout "${@}"; }
gl () { git pull "${@}"; }
gm () { git commit -m "${@}"; }
gma () { git commit --amend "${@}"; }
gp () { git push "${@}"; }
gpl () { git unpushed "${@}"; }
gr () { git root "${@}"; }
gs () { git status -s -uall "${@}"; }
gsd () { git stash drop "${@}"; }
gsp () { git stash pop "${@}"; }
gst () { git stash push "${@}"; }
gu () { git uncommit "${@}"; }

ti () { command tig "${@}"; }
tb () { command tig blame "${@}"; }
tg () { command tig grep "${@}"; }

tx () { command direnv exec / \tmux "${@}"; }
ta () { tmux attach "${@}"; }

du () { command docker compose up -d "${@}"; }
dub () { command docker compose up -d --build "${@}"; }
dd () { command docker compose down "${@}"; }
dls () { command docker ps -a "${@}"; }
dlsi () { command docker image ls "${@}"; }
dlsv () { command docker volume ls "${@}"; }
drm () { command docker rm -f $(command docker ps -a -q); }
drmi () { command docker rmi -f $(command docker images -a -q); }
drmv () { command docker volume rm -f $(command docker volume ls -f dangling=true -q); }
ds () { command docker compose start; }
dt () { if [[ ${dt_USER} ]]; then command docker exec -it --user "${dt_USER}" "${@}"; else command docker exec -it "${@}"; fi; }
dy () { command docker system prune -a -f; }
