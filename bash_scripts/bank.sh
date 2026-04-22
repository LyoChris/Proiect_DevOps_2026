#!/bin/bash

FILE="bank.csv"

init_file() {
    if [ ! -f "$FILE" ]; then
        echo "Client,Sold curent" > "$FILE"
    fi
}

add_client() {
    read -p "Nume client nou: " name

    if [ -z "$name" ]; then
        echo "Numele nu poate fi gol."
        return
    fi

    if grep -i "^$name," "$FILE" > /dev/null; then
        echo "Clientul exista deja."
        return
    fi

    echo "$name,0" >> "$FILE"
    echo "Client adaugat cu succes."
}

update_balance() {
    read -p "Nume client: " name

    if ! grep -i "^$name," "$FILE" > /dev/null; then
        echo "Clientul nu exista."
        return
    fi

    current_balance=$(grep -i "^$name," "$FILE" | head -n 1 | cut -d',' -f2)

    echo "Sold curent: $current_balance"
    echo "1. Depune bani"
    echo "2. Retrage bani"
    read -p "Alege optiunea: " option
    read -p "Suma: " amount

    if ! [[ "$amount" =~ ^[0-9]+$ ]]; then
        echo "Suma invalida. Introdu un numar intreg pozitiv."
        return
    fi

    if [ "$option" = "1" ]; then
        new_balance=$((current_balance + amount))
    elif [ "$option" = "2" ]; then
        if [ "$amount" -gt "$current_balance" ]; then
            echo "Operatie invalida. Soldul nu poate deveni negativ."
            return
        fi
        new_balance=$((current_balance - amount))
    else
        echo "Optiune invalida."
        return
    fi

    temp_file="temp.csv"
    echo "Client,Sold curent" > "$temp_file"

    while IFS=, read -r client sold; do
        if [ "$client" = "Client" ]; then
            continue
        fi

        if [ "${client,,}" = "${name,,}" ]; then
            echo "$client,$new_balance" >> "$temp_file"
        else
            echo "$client,$sold" >> "$temp_file"
        fi
    done < "$FILE"

    mv "$temp_file" "$FILE"
    echo "Sold actualizat cu succes."
}

delete_client() {
    read -p "Nume client de sters: " name

    if ! grep -i "^$name," "$FILE" > /dev/null; then
        echo "Clientul nu exista."
        return
    fi

    temp_file="temp.csv"
    echo "Client,Sold curent" > "$temp_file"

    while IFS=, read -r client sold; do
        if [ "$client" = "Client" ]; then
            continue
        fi

        if [ "${client,,}" != "${name,,}" ]; then
            echo "$client,$sold" >> "$temp_file"
        fi
    done < "$FILE"

    mv "$temp_file" "$FILE"
    echo "Client sters cu succes."
}

show_clients() {
    if [ "$(wc -l < "$FILE")" -le 1 ]; then
        echo "Nu exista clienti."
        return
    fi

    echo
    printf "%-20s | %-15s\n" "Client" "Sold curent"
    echo "------------------------------------------"

    while IFS=, read -r client sold; do
        if [ "$client" = "Client" ]; then
            continue
        fi

        printf "%-20s | %-15s\n" "$client" "$sold"
    done < "$FILE"

    echo
}

show_menu() {
    echo
    echo "1. Adauga client"
    echo "2. Modifica sold"
    echo "3. Sterge client"
    echo "4. Afiseaza toti clientii"
    echo "5. Iesire"
}

init_file

while true; do
    show_menu
    read -p "Alege o optiune: " option

    case $option in
        1) add_client ;;
        2) update_balance ;;
        3) delete_client ;;
        4) show_clients ;;
        5) echo "La revedere!"; exit 0 ;;
        *) echo "Optiune invalida." ;;
    esac
done
