                  #!/bin/bash                                                                                               RED='\033[0;31m'                                     GREEN='\033[0;32m'                                   YELLOW='\033[1;33m'                                  BLUE='\033[0;34m'                                    CYAN='\033[0;36m'                                    PURPLE='\033[0;35m'                                  ORANGE='\033[0;33m'                                  MAGENTA='\033[1;35m'                                 NC='\033[0m'                                                                                              SHOW_DESC=0                                          SHOW_REF=0                                           DOMAIN=""                                            MODE="all"                                           USER_AGENT_FILE=""                                   PROXY_LIST=""                                        USE_PROXY=0                                                                                               random_ip() {                                            echo $((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))                                  }                                                                                                         get_random_ua() {                                        if [[ -f "$USER_AGENT_FILE" && -s "$USER_AGENT_FILE" ]]; then
        shuf -n 1 "$USER_AGENT_FILE"
    else
        local uas=(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15"
            "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"
            "Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36"
            "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"
        )
        echo "${uas[$RANDOM % ${#uas[@]}]}"
    fi
}

get_random_proxy() {
    if [[ -f "$PROXY_LIST" && -s "$PROXY_LIST" ]]; then
        shuf -n 1 "$PROXY_LIST"
    else
        echo ""
    fi
}

show_help() {
    echo -e "${GREEN}Tech Hunter for Bug Bounty${NC}"
    echo "Usage: $0 [options] <domain>"
    echo ""
    echo "Options:"
    echo "  -t, --tech      Show technology information only"
    echo "  -e, --email     Show email information only"
    echo "  -d, --desc      Show technology descriptions"
    echo "  -r, --ref       Show technology references"
    echo "  -a, --all       Show both descriptions and references"
    echo "  -p, --proxy     Use random proxy from proxies.txt"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d -p example.com        # Use proxy with descriptions"
    echo "  $0 -e -v example.com       # Verbose email discovery"
    echo "  $0 -a -t example.com        # Full tech details"
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--desc) SHOW_DESC=1 ;;
        -r|--ref) SHOW_REF=1 ;;
        -a|--all) SHOW_DESC=1; SHOW_REF=1 ;;
        -t|--tech) MODE="tech" ;;
        -e|--email) MODE="email" ;;
        -p|--proxy) USE_PROXY=1 ;;
        -h|--help) show_help ;;
        *)
            if [[ -z "$DOMAIN" ]]; then
                DOMAIN="$1"
            else
                echo -e "${RED}Error: Multiple domains specified${NC}"
                show_help
                exit 1
            fi
            ;;
    esac
    shift
done

if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}Error: Domain is required${NC}"
    show_help
    exit 1
fi

make_api_request() {
    local endpoint="$1"
    local form_field="$2"
    local domain="$3"

    local rand_ip=$(random_ip)
    local rand_ua=$(get_random_ua)

    local headers=(
        "--header" "User-Agent: $rand_ua"
        "--header" "Accept: application/json, text/plain, */*"
        "--header" "Accept-Encoding: gzip, deflate, br, zstd"
        "--header" "sec-ch-ua-platform: \"Windows\""
        "--header" "sec-ch-ua: \"Chromium\";v=\"116\", \"Not)A;Brand\";v=\"24\""
        "--header" "sec-ch-ua-mobile: ?0"
        "--header" "Origin: https://ful.io"
        "--header" "Sec-Fetch-Site: same-site"
        "--header" "Sec-Fetch-Mode: cors"
        "--header" "Sec-Fetch-Dest: empty"
        "--header" "Referer: https://ful.io/"
        "--header" "Accept-Language: en-US,en;q=0.9"
        "--header" "X-Forwarded-For: $rand_ip"
        "--header" "X-Forwarded-Host: $domain"
        "--header" "X-Real-IP: $rand_ip"
    )

    local proxy_cmd=()
    if [[ $USE_PROXY -eq 1 ]]; then
        local proxy=$(get_random_proxy)
        if [[ -n "$proxy" ]]; then
            proxy_cmd=("--proxy" "$proxy")
            [[ $VERBOSE -eq 1 ]] && echo -e "${PURPLE}Using proxy: ${BLUE}$proxy${NC}"
        fi
    fi

    curl -s --location --request POST "$endpoint" \
        "${headers[@]}" \
        "${proxy_cmd[@]}" \
        --form "${form_field}=${domain}" \
        --compressed \
        --connect-timeout 15 \
        --max-time 30
}

run_tech_recon() {
    local response="$1"
    domain_name=$(echo "$response" | jq -r '.domain_name')
    if [[ -z "$domain_name" || "$domain_name" == "null" ]]; then
        echo -e "${YELLOW}ℹ No technology data found for ${DOMAIN}${NC}"
        return
    fi
    touch "$domain_name.tech"
    title=$(echo "$response" | jq -r '.title')
    description=$(echo "$response" | jq -r '.description')
    date_established=$(echo "$response" | jq -r '.date_established')

    echo -e "${GREEN}"
    echo "┌───────────────────────────────────────┐"
    echo "│        World Off,Terminal On          │"
    echo "└───────────────────────────────────────┘"
    echo -e "${YELLOW}▐${PURPLE} Domain      ${YELLOW}▌${NC} ${CYAN} ${domain_name} ${NC}"
    [[ "$title" != "null" && -n "$title" ]] && echo -e "${YELLOW} ▐${PURPLE} Title      ${YELLOW} ▌ ${CYAN} ${title} ${NC}  ${NC}"
    [[ "$description" != "null" && -n "$description" ]] && echo -e "${YELLOW}▐${PURPLE} Description ${YELLOW}▌${NC}${CYAN} ${description} ${NC}"
    [[ "$date_established" != "null" ]] && echo -e "${CYAN}Established:   ${ORANGE}${date_established}${NC}"
    echo ""

    social_links=$(echo "$response" | jq -c '.social_links[]?')
    if [[ -n "$social_links" ]]; then
        echo -e "${YELLOW}▐${PURPLE} Social Links ${YELLOW}▌${NC}"
        while IFS= read -r link; do
            platform=$(echo "$link" | jq -r '.platform')
            url=$(echo "$link" | jq -r '.url')
            platform="${platform^}"
            echo -e "  ${GREEN}• ${CYAN}${platform}: ${BLUE}https://${url}${NC}"
        done <<< "$social_links"
        echo ""
    fi

    categories=$(echo "$response" | jq -c '.technologies[]?')
    if [[ -n "$categories" ]]; then
        echo -e "${YELLOW}▐${PURPLE} Detected Technologies ${YELLOW}▌${NC}"
        total_tech=0

        options_info=""
        [[ $SHOW_DESC -eq 1 ]] && options_info+="(descriptions) "
        [[ $SHOW_REF -eq 1 ]] && options_info+="(references)"
        [[ -n "$options_info" ]] && echo -e "${BLUE}Display options: ${ORANGE}${options_info}${NC}\n"
        while IFS= read -r category; do
            category_name=$(echo "$category" | jq -r '.category_name')
            tech_count=$(echo "$category" | jq '.technologies | length')
            ((total_tech += tech_count))

            echo -e "\n${ORANGE}» ${category_name} (${tech_count})${NC}"

            echo "$category" | jq -c '.technologies[]' | while read -r tech; do
                name=$(echo "$tech" | jq -r '.name')
                desc=$(echo "$tech" | jq -r '.description')
                website=$(echo "$tech" | jq -r '.website')

                echo -e "  ${GREEN}◆ ${CYAN}${name}${NC}"

                if [[ $SHOW_DESC -eq 1 ]]; then
                    [[ "$desc" == "null" || -z "$desc" ]] && desc="No description available"
                    echo -e "    ${BLUE}${desc}${NC}"
                fi

                if [[ $SHOW_REF -eq 1 ]]; then
                    [[ "$website" == "null" || -z "$website" ]] && website="No reference available"
                    echo -e "    ${YELLOW}↳ Reference: ${BLUE}${website}${NC}"
                fi
            done
        done <<< "$categories"

        echo -e ""
    else
        echo -e "${YELLOW}No technologies detected${NC}"
    fi
}

run_email_recon() {
    local response="$1"
    domain=$(echo "$response" | jq -r '.domain')
    unique_emails=$(echo "$response" | jq -r '.["total unique emails found"]')
    total_occurrences=$(echo "$response" | jq -r '.["total email occurrences"]')
    results=$(echo "$response" | jq -c '.results_found[]?')

    if [[ -z "$results" || "$results" == "null" ]]; then
        echo -e "${YELLOW}ℹ No email addresses found for ${DOMAIN}${NC}"
        return
    fi
    echo -e "${YELLOW}▐${PURPLE} Discovered Email Addresses ${YELLOW}▌${NC}"

    while IFS= read -r result; do
        email=$(echo "$result" | jq -r '.Email')
        urls=$(echo "$result" | jq -r '.URLs[]?')

        echo -e "\n${ORANGE}↳ ${CYAN}${email}${NC}"
          done <<< "$results"

}

if [[ "$MODE" == "all" || "$MODE" == "tech" ]]; then
    tech_response=$(make_api_request "https://api.ful.io/domain-search" "url" "$DOMAIN")

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Failed to connect to Technology API${NC}"
    else
        error=$(echo "$tech_response" | jq -r '.error')
        if [[ "$error" != "null" && -n "$error" ]]; then
            echo -e "${RED}✗ Technology API Error: ${error}${NC}"
        else
            run_tech_recon "$tech_response"
        fi
    fi
    echo ""
fi

if [[ "$MODE" == "all" || "$MODE" == "email" ]]; then
    email_response=$(make_api_request "https://api.ful.io/email-search-website" "domain_url" "$DOMAIN")

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Failed to connect to Email API${NC}"
    else
        error=$(echo "$email_response" | jq -r '.error')
        if [[ "$error" != "null" && -n "$error" ]]; then
            echo -e "${RED}✗ Email API Error: ${error}${NC}"
            else
            run_email_recon "$email_response"
        fi
    fi
fi
