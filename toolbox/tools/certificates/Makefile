# from https://gist.github.com/xenogenesi/1b2137f769aa80b6c99d573071f5d086
# and https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309

DOMAIN ?=
NAME ?=

ifeq ($(DOMAIN),)
  $(error DOMAIN is not set)
endif

ifeq ($(NAME),)
  $(error NAME is not set)
endif

COUNTRY := DE
STATE := DE
COMPANY := $(NAME)

all: $(NAME).rootCA.crt $(DOMAIN).crt

$(NAME).rootCA.key:
	openssl genrsa -des3 -out $(NAME).rootCA.key 4096

# Create and self sign root certificate
$(NAME).rootCA.crt: $(NAME).rootCA.key
	echo -e "$(COUNTRY)\n$(STATE)\n\n$(COMPANY)\n\n\n\n" | openssl req -x509 -new -nodes -key $(NAME).rootCA.key -sha256 -days 1825 -out $@

$(DOMAIN).key:
	openssl genrsa -out $@ 2048

$(DOMAIN).conf:
	sh mkconf.sh $(DOMAIN) >$@

$(DOMAIN).csr: $(DOMAIN).key $(DOMAIN).conf
	openssl req -new -sha256 -key $(DOMAIN).key -subj "/C=$(COUNTRY)/ST=$(STATE)/O=$(COMPANY)/CN=$(DOMAIN)" \
		-reqexts SAN \
		-config $(DOMAIN).conf \
		-out $@

# verify .csr content
.PHONY: verify-csr
verify-csr:
	openssl req  -in $(DOMAIN).csr -noout -text

$(DOMAIN).san.conf:
	sh mksan.sh $(DOMAIN) $(COUNTRY) $(STATE) "$(COMPANY)" >$@

$(DOMAIN).crt: $(NAME).rootCA.key $(NAME).rootCA.crt $(DOMAIN).csr $(DOMAIN).san.conf
	openssl x509 -req -in $(DOMAIN).csr -CA ./$(NAME).rootCA.crt -CAkey ./$(NAME).rootCA.key \
		-CAcreateserial -out $@ -days 1825 -sha256 \
		-extfile $(DOMAIN).san.conf -extensions req_ext

# verify the certificate
.PHONY: verify-crt
verify-crt:
	openssl x509 -in $(DOMAIN).crt -text -noout

.PHONY: clean
clean:
	rm -f $(NAME).rootCA.crt $(NAME).rootCA.key $(NAME).rootCA.srl $(DOMAIN).key $(DOMAIN).csr $(DOMAIN).conf $(DOMAIN).san.conf $(DOMAIN).crt

.PHONY: help
help:
	@echo "Usage:"
	@echo "make DOMAIN=domain.com NAME=productName"
	@echo "make DOMAIN=domain.com NAME=productName verify-csr"
	@echo "make DOMAIN=domain.com NAME=productName verify-crt"
	@echo "---"
	@echo "Import $(NAME).rootCA.crt to the client (chrome)"
	@echo "Upload $(DOMAIN).crt and $(DOMAIN).key to the host"

