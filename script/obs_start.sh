#!/bin/bash
###################################################
#Definições para uso global
perfis=("STUDIO-DUXUS" "LIVE-TESTE")
colecoes=("LIVE-UNICA" "LIVE-DUPLA")
cenas=("[LIVE-DUPLA]1-CENTRAL" "[LIVE-DUPLA]2-DIREITO" "[LIVE-DUPLA]3-ESQUERDO" "[LIVE-DUPLA]4-CENTRAL-UNICA" "[LIVE-DUPLA]5-DIREITO-UNICA" "[LIVE-DUPLA]6-ESQUERDO-UNICA" "[LIVE-UNICA]1-CENTRAL-U" "[LIVE-UNICA]2-DIREITO-U" "[LIVE-UNICA]3-ESQUERDO-U" )
caminho_sh="/usr/share/OBSLive/bin"
###################################################
#########################
# Ajuda
#########################
display_help() {
    echo "Uso: $0 [opções...]" >&2
    echo
    echo "	-h,	--help			Exibe as opções de utilização"
    echo "	-p,	--perfil <perfil>	Utiliza ou tenta utilizar o perfil indicado"
    echo "	-c,	--colecao <colecao>	Utiliza ou tenta utilizar a coleção de cenas indicada"
    echo "	-s,	--cena <cena>		Utiliza ou tenta utilizar a cena indicada. Deve pertencer à coleção de cena escolhida (parâmetro -c obrigatório)"
    echo "	-k,	--kill			Finaliza execução do OBS se já estiver rodando"
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}
get_index() {	
	valor=$1
	shift
	opcoes=("$@")	
	for i in "${!opcoes[@]}"; do	
		#remove indetificadores de colecoes	
		elemento=${opcoes[$i]//\[*\]/}				
		if [[ $elemento = "${valor}" ]]; then	
			ptr=${i}
			((ptr++))
		   return $ptr
		fi
	done
	return 0
}
confirm() {
	mensagem=$1
	if [[ $mensagem == null ]]; then
		$mensagem = "Escolha uma opção"
	fi
	aviso=""
    while true; do
        read -p "$aviso$mensagem (S/N): " result
        case $result in
            "S" | "s" | "Sim" | "SIM") return 0;;
            "N" | "n" | "NÃO" | "Não"  | "nao" | "NAO") return 1;;
            *) aviso=$'Por favor, informe [S]im ou [N]ão!!\n';;
        esac
    done
}
escolha() {
	mensagem=$1
	if [[ $mensagem == null ]]; then
		echo "Erro de implantação de escolha para MENSAGEM"
		sleep 2
		exit
	fi
	echo $"$mensagem"
	shift
	opcoes=("$@")
	if [[ $opcoes == null ]]; then
		echo "Erro de implantação de escolha para OPÇÕES"
		sleep 2
		exit
	fi	
	#echo ${opcoes[@]}
	result=-1
	while [ $result -lt 0 ]; do
		echo "0) Não utilizar"
		ptr=1	
		for i in "${opcoes[@]}"; do
			echo "$ptr) $i"
			((ptr++))
		done
		echo "$ptr) Abortar"
		read -p "Escolha uma opção: " result 		
		#Verifica se opção é valida
		#Primeiro verifica abortar		
		if [[ $result == $ptr ]]; then
			echo "Processo abortado."
			sleep 2
			exit;
		fi
		#Deve retornar a opção escolhida e senão ultrapassar o total
		if [[ $result > $ptr ]]; then
			echo "Opção INVÁLIDA. Valores devem ser entre 1 e $ptr!"
			result=-1
		fi
		if [[ $result -ge 0 ]]; then
			echo "Opção escolhida: ${opcoes[$result-1]}"
			return $result
		fi				
	done	
}	
perfil=0
colecao=0
cena=0
#Iniciando uso do sistema
while :
do
	case "$1" in     
	  -h | --help)
		  display_help 
		  exit 0
		  ;;   
	  -p | --perfil)
			nome_perfil="$2"			
			get_index "$nome_perfil" "${perfis[@]}"		
			perfil=$?			
			shift 2	
		  ;;   
	  -c | --colecao)
			nome_colecao="$2"
			get_index "$nome_colecao" "${colecoes[@]}"		
			colecao=$?									
			shift 2	
		  ;;  
	  -s | --cena)
			nome_cena="$2"
			get_index "$nome_cena" "${cenas[@]}"		
			cena=$?					
			shift 2	
		  ;;
	  -k | --kill)
			kill=true
			shift 1	
		  ;;
	  -*)
		echo "Erro: opção inválida: $1" >&2
			exit 1 
			;;
	  *)  # No more options	  
			break;
		  ;;
	esac
done
echo "Iniciando OBS..."
#Adiciona comando ao path se não existir
path_atual=$PATH
echo "Verificando PATH...."	
#Verifica se contém camainho
if [[ $path_atual == *"$caminho_sh"* ]]; then
	echo "Executável já presente em PATH!"	
else	
	echo "Adicionando Executável ao PATH: $caminho_sh"
	arquivo=/etc/profile.d/obs_start_path.sh
	#VERIFICA SE TEM .BASHRC
	if [ -f "$arquivo" ]; then
		echo "Arquivo SH PROFILE.D localizado. Comando será adicionado se não existir."
	else
		echo "Arquivo SH PROFILE.D não localizado. Será criado"
		$(sudo touch $arquivo)
		if [ -f "$arquivo" ]; then
			echo "Arquivo SH PROFILE.D criado!"
		else
			echo "Erro de criação de arquivo SH PROFILE.D. Abortado."
			exit
		fi
	fi		
	#Verifica se arquivo contém já o conteúdo
	miolo="export PATH=\$PATH:$caminho_sh"
	linha="echo '$miolo' | sudo tee -a $arquivo"
	conteudo=$(cat $arquivo)
	echo "Conteúdo atual:"
	echo "$conteudo"
	if [[ $conteudo == *"$miolo"* ]]; then
		echo "Linha já existente em PROFILE.D. Verificar validade de PATH via PROFILE.D!!"	
	else
		echo $linha
		sudo sh -c $linha		
		
		echo "Adicionado PATH por PROFILE.D"	
	fi
fi
#Verifica se já esta rodando pelo pgrep
#Testa resultado e devide o que fazer
output=$(pgrep -x obs)
#echo $output
if [[ $output != "" ]]; then
    echo "OBS já está em execução!"
    if [[ $kill == "" ]]; then
		confirm "Deseja REINICIAR o OBS?"
		acao=$?
		if [[ $acao == 1 ]]; then
			echo "Processo abortado."
			sleep 2
			exit;
		else
			#Precisa finializar o OBS
			echo "Finalizando execução atual..."
			output=$(kill -9 $output)
			echo "Finalizando."
		fi
	else
		output=$(kill -9 $output)
		echo "Finalizando."
	fi
fi
#Escolha de PERFIL
echo "###################################################"
if [[ $perfil -eq 0 ]]; then
	if [[ $nome_perfil !=  "" ]]; then
		echo "Parâmetro PERFIL incorreto. Ignorado"
	fi
	msg='Escolha o perfil PREVIAMENTE existente: '
	escolha "$msg" "${perfis[@]}"
	perfil=$?
else
    echo "Perfil por parâmetro: ${perfis[$perfil-1]}"		
fi	
echo "###################################################"
#Escolha de COLEÇÃO
if [[ $colecao -eq 0 ]]; then
	if [[ $nome_colecao !=  "" ]]; then
		echo "Parâmetro COLECAO DE CENAS incorreto. Ignorado"
	fi
	msg="Escolha a COLEÇÃO DE CENAS PREVIAMENTE existente: "
	escolha "$msg" "${colecoes[@]}"
	colecao=$?
else
    echo "Coleção por parâmetro: ${colecoes[$colecao-1]}"		
fi	
echo "###################################################"
cenas_colecao=()
#Se a coleção for 0, não escolhe CENA
if [[ $colecao -gt 0 ]]; then
	#Outro vetor de cenas deve ser montado	
	for i in "${!cenas[@]}"; do	
		#remove indetificadores de colecoes	
		elemento=${cenas[$i]}				
		# Remove everything before and including the first '['
		elemento="${elemento#*[}"
		# Remove everything starting from the first ']' in the new string
		result="${elemento%%]*}"		
		if [[ $result == ${colecoes[$colecao-1]} ]]; then			
			elemento=${cenas[$i]//\[*\]/}			
			cenas_colecao+=($elemento)
		fi	
	done	
	#Escolha de CENA	
	# O ìndice precisa ser refeito - nem preciaria ser feito no início!!		
	#Porem, apenas se informado
	if [[ $nome_cena != "" ]]; then	
		get_index "$nome_cena" "${cenas_colecao[@]}"		
		cena=$?
		if [[ $cena -eq 0 ]]; then
			echo "Parâmetro CENA incorreto. Ignorado"
		fi	
	fi		
	if [[ $cena -eq 0 ]]; then	
		msg="Escolha a CENA PREVIAMENTE existente: "	
		escolha "$msg" "${cenas_colecao[@]}"
		cena=$?
	else 		
		echo "Cena por parâmetro: ${cenas_colecao[$cena-1]}"		
	fi	
else
	echo "COLEÇÃO não utilizada. CENA não será aplicada!"
fi
echo "###################################################"
#Inicializa o OBS com as opções selecionadas
cmd_perfil=""
if [[ $perfil -gt 0 ]]; then	
	cmd_perfil=$"--profile ${perfis[$perfil-1]}"
fi
cmd_colecao=""
cmd_cena=""
if [[ $colecao -gt 0 ]]; then	
	cmd_colecao=$"--collection ${colecoes[$colecao-1]}"
	if [[ $cena -gt 0 ]]; then	
		cmd_cena=$"--scene ${cenas_colecao[$cena-1]}"
	fi
fi

echo "Startando OBS..."
comando="obs $cmd_perfil $cmd_colecao $cmd_cena"
echo "Comando: $comando"
nohup $comando < /dev/null &
echo "OBS Pronto para uso!"
sleep 3


