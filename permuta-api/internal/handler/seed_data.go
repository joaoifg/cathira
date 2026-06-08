package handler

// Dados mockados ricos pra dev/demo. Fotos via picsum.photos (estáveis por seed).

func picsum(seed string) string {
	return "https://picsum.photos/seed/" + seed + "/600/400"
}

var personasMundo = []seedPersona{
	{
		nome: "Maria Souza", email: "demo+maria@local.test", cidade: "São Paulo",
		lotes: []seedLote{
			{"Carro popular completo", "automoveis", 50000, 120000, []seedItem{
				{"Onix 2022 LT", "hatch", "Hatch flex, único dono, 18mil km", 78000,
					map[string]string{"ano": "2022", "km": "18000", "cambio": "manual", "combustivel": "flex"}, picsum("onix22")},
				{"Hilux usada", "picape", "2014, diesel, ótima conservação", 95000,
					map[string]string{"ano": "2014", "km": "180000", "cambio": "manual", "combustivel": "diesel"}, picsum("hilux14")},
			}},
			{"Bike speed + skate", "esportivo", 1500, 4500, []seedItem{
				{"Bike Caloi Strada", "bola", "Caloi Strada Racing 2023, quadro 56", 4200,
					map[string]string{"tamanho": "M", "marca": "Caloi", "estado": "usado"}, picsum("caloi-bike")},
				{"Skate Element completo", "uniforme", "Shape novo, trucks Independent", 650,
					map[string]string{"tamanho": "8.0", "marca": "Element", "estado": "usado"}, picsum("skate-elem")},
			}},
			{"Biblioteca pessoal", "livros", 400, 1500, []seedItem{
				{"Coleção Harry Potter completa", "literatura", "7 livros capa dura Rocco", 980,
					map[string]string{"autor": "J.K. Rowling", "editora": "Rocco", "ano": "2018", "estado": "seminovo"}, picsum("hp-set")},
				{"Sandman edição definitiva 1", "hq", "Volume 1, em inglês, capa dura", 280,
					map[string]string{"autor": "Neil Gaiman", "editora": "Vertigo", "ano": "2020", "estado": "novo"}, picsum("sandman")},
			}},
		},
	},
	{
		nome: "Pedro Lima", email: "demo+pedro@local.test", cidade: "Rio de Janeiro",
		lotes: []seedLote{
			{"Kit fotógrafo iniciante", "eletronicos", 4000, 10000, []seedItem{
				{"Canon EOS R50", "camera", "Mirrorless APS-C com 18-45mm kit", 6500,
					map[string]string{"marca": "Canon", "modelo": "R50", "ano": "2023", "estado": "seminovo"}, picsum("canon-r50")},
				{"Tripé Manfrotto + bag", "audio", "Manfrotto Befree + bolsa", 850,
					map[string]string{"marca": "Manfrotto", "estado": "usado"}, picsum("tripe-manf")},
			}},
			{"Notebook + console", "eletronicos", 12000, 22000, []seedItem{
				{"Dell XPS 15", "notebook", "Intel i7, 32GB RAM, 1TB SSD", 11000,
					map[string]string{"marca": "Dell", "modelo": "XPS 15", "ano": "2022", "estado": "seminovo"}, picsum("dell-xps")},
				{"Xbox Series X", "console", "1TB + 3 jogos físicos", 4800,
					map[string]string{"marca": "Microsoft", "modelo": "Series X", "ano": "2023", "estado": "seminovo"}, picsum("xbox-x")},
			}},
		},
	},
	{
		nome: "Ana Pereira", email: "demo+ana@local.test", cidade: "Belo Horizonte",
		lotes: []seedLote{
			{"Pacote estúdio + DJ", "instrumentos", 6000, 15000, []seedItem{
				{"Controlador Pioneer DDJ", "estudio", "Pioneer DDJ-FLX6 GT", 5800, nil, picsum("pioneer-ddj")},
				{"Caixa de som JBL EON", "audio", "JBL EON615 ativa", 3200, nil, picsum("jbl-eon")},
				{"MacBook Air M1", "notebook", "MacBook Air 2020 M1, 8GB", 4500,
					map[string]string{"marca": "Apple", "modelo": "Air M1", "ano": "2020", "estado": "usado"}, picsum("mba-m1")},
			}},
			{"Bateria acústica completa", "instrumentos", 3000, 8000, []seedItem{
				{"Bateria Mapex Tornado", "bateria", "5 peças + pratos + estantes", 4500, nil, picsum("mapex-tornado")},
				{"Pad de prática Remo", "bateria", "Pad 12 pol", 250, nil, picsum("pad-remo")},
			}},
			{"Apto 2 quartos no centro", "imoveis", 280000, 380000, []seedItem{
				{"Apto 60m² em BH", "apto", "2 quartos, 1 vaga, sacada, centro", 320000,
					map[string]string{"metragem": "60", "quartos": "2", "vagas": "1", "cidade": "Belo Horizonte"}, picsum("apto-bh-1")},
			}},
		},
	},
	{
		nome: "Carlos Mendes", email: "demo+carlos@local.test", cidade: "Curitiba",
		lotes: []seedLote{
			{"Setup escritório home", "eletronicos", 8000, 14000, []seedItem{
				{"Monitor LG ultrawide 34''", "tv", "LG 34WN80C, USB-C 60W", 3800,
					map[string]string{"marca": "LG", "modelo": "34WN80C", "ano": "2022", "estado": "seminovo"}, picsum("lg-ultra")},
				{"Mesa elétrica + cadeira", "audio", "Mesa height-adjustable + Herman Miller usada", 6200,
					map[string]string{"marca": "Flexform", "estado": "usado"}, picsum("home-office")},
			}},
			{"Carro família", "automoveis", 60000, 110000, []seedItem{
				{"Compass Limited 2021", "suv", "Diesel 4x4, 45mil km", 138000,
					map[string]string{"ano": "2021", "km": "45000", "cambio": "automatico", "combustivel": "diesel"}, picsum("compass-21")},
			}},
		},
	},
	{
		nome: "Beatriz Cardoso", email: "demo+beatriz@local.test", cidade: "Florianópolis",
		lotes: []seedLote{
			{"Surf life", "esportivo", 800, 3000, []seedItem{
				{"Prancha Channel Islands 6'2", "uniforme", "Pranchinha CI Happy Everyday", 2200,
					map[string]string{"tamanho": "6'2", "marca": "Channel Islands", "estado": "usado"}, picsum("prancha-ci")},
				{"Neoprene Rip Curl 3/2", "uniforme", "Tamanho M, ótimo estado", 700,
					map[string]string{"tamanho": "M", "marca": "Rip Curl", "estado": "usado"}, picsum("neoprene-rc")},
				{"Roof rack Yakima", "luva", "Suporte universal pra 2 pranchas", 320,
					map[string]string{"tamanho": "univ", "marca": "Yakima", "estado": "usado"}, picsum("rack-yakima")},
			}},
			{"Camping de praia", "outdoor", 600, 2500, []seedItem{
				{"Barraca Coleman 4 pessoas", "barraca", "Sundome 4P + sobreteto", 850,
					map[string]string{"tamanho": "4P", "marca": "Coleman", "estado": "usado"}, picsum("coleman-tent")},
				{"Cooler Yeti Roadie 24", "camping", "Térmico 24L, segura gelo 4 dias", 1400,
					map[string]string{"tamanho": "24L", "marca": "Yeti", "estado": "seminovo"}, picsum("yeti-roadie")},
			}},
		},
	},
	{
		nome: "Rafael Vargas", email: "demo+rafael@local.test", cidade: "Porto Alegre",
		lotes: []seedLote{
			{"Studio musical do gaúcho", "instrumentos", 8000, 18000, []seedItem{
				{"Gibson Les Paul Studio", "guitarra", "2019, faded mahogany", 9800, nil, picsum("gibson-lp")},
				{"Marshall DSL40", "guitarra", "Combo valvulado 40W", 3200, nil, picsum("marshall-dsl")},
				{"Pedalboard completo", "guitarra", "8 pedais boutique + case", 2800, nil, picsum("pedalboard")},
			}},
			{"Vinil + toca-discos", "instrumentos", 1500, 4000, []seedItem{
				{"Toca-discos Pro-Ject", "audio", "Pro-Ject Debut Carbon", 2400, nil, picsum("project-tt")},
				{"Coleção 80 vinis", "audio", "Clássicos do rock e MPB", 1600, nil, picsum("vinil-collection")},
			}},
		},
	},
	{
		nome: "Juliana Castro", email: "demo+juliana@local.test", cidade: "Salvador",
		lotes: []seedLote{
			{"Smartphones premium", "eletronicos", 5000, 14000, []seedItem{
				{"iPhone 15 Pro 256GB", "smartphone", "Titânio natural, 100% bateria", 7800,
					map[string]string{"marca": "Apple", "modelo": "15 Pro", "ano": "2023", "estado": "seminovo"}, picsum("iphone15p")},
				{"Galaxy S24 Ultra", "smartphone", "512GB, com S Pen, perfeito", 6900,
					map[string]string{"marca": "Samsung", "modelo": "S24 Ultra", "ano": "2024", "estado": "novo"}, picsum("s24-ultra")},
			}},
			{"Casa de praia", "imoveis", 350000, 600000, []seedItem{
				{"Casa 3 quartos em Itapuã", "casa", "Quintal, 2 vagas, perto da praia", 480000,
					map[string]string{"metragem": "140", "quartos": "3", "vagas": "2", "cidade": "Salvador"}, picsum("casa-bahia")},
			}},
		},
	},
	{
		nome: "Lucas Tavares", email: "demo+lucas@local.test", cidade: "Recife",
		lotes: []seedLote{
			{"Bike mountain bike", "esportivo", 2500, 6500, []seedItem{
				{"Specialized Rockhopper", "bola", "MTB 29, grupo Deore", 4200,
					map[string]string{"tamanho": "L", "marca": "Specialized", "estado": "usado"}, picsum("spec-rh")},
				{"Capacete Bell + acessórios", "luva", "Bell + GPS Garmin Edge", 1100,
					map[string]string{"tamanho": "L", "marca": "Bell", "estado": "usado"}, picsum("capacete-bell")},
			}},
			{"Drone + câmera de ação", "eletronicos", 4000, 9000, []seedItem{
				{"DJI Mini 4 Pro", "camera", "Drone + 3 baterias + Smart Controller", 5800,
					map[string]string{"marca": "DJI", "modelo": "Mini 4 Pro", "ano": "2024", "estado": "novo"}, picsum("dji-mini4")},
				{"GoPro Hero 12", "camera", "Black + acessórios", 2400,
					map[string]string{"marca": "GoPro", "modelo": "Hero 12", "ano": "2024", "estado": "seminovo"}, picsum("gopro12")},
			}},
		},
	},
	{
		nome: "Fernanda Rocha", email: "demo+fernanda@local.test", cidade: "Fortaleza",
		lotes: []seedLote{
			{"Mãe trocando carro", "automoveis", 70000, 140000, []seedItem{
				{"HRV 2021 EXL", "suv", "SUV automático, top de linha", 132000,
					map[string]string{"ano": "2021", "km": "38000", "cambio": "automatico", "combustivel": "flex"}, picsum("hrv-21")},
			}},
			{"Eletrodomésticos top", "eletronicos", 6000, 14000, []seedItem{
				{"Geladeira Brastemp Inverse", "tv", "Side by side 540L", 5400,
					map[string]string{"marca": "Brastemp", "modelo": "Inverse", "ano": "2023", "estado": "seminovo"}, picsum("brastemp")},
				{"Cooktop indução Tramontina", "tv", "5 bocas, novo", 3800,
					map[string]string{"marca": "Tramontina", "ano": "2024", "estado": "novo"}, picsum("cooktop")},
				{"Lava-louças Electrolux", "tv", "10 serviços, A++", 3200,
					map[string]string{"marca": "Electrolux", "ano": "2023", "estado": "seminovo"}, picsum("dishwasher")},
			}},
		},
	},
	{
		nome: "Thiago Andrade", email: "demo+thiago@local.test", cidade: "Brasília",
		lotes: []seedLote{
			{"Setup gamer pesado", "eletronicos", 18000, 35000, []seedItem{
				{"PC Gamer RTX 4080", "console", "Ryzen 9, 64GB DDR5, 4TB SSD", 22000,
					map[string]string{"marca": "Custom", "ano": "2024", "estado": "novo"}, picsum("pc-rtx4080")},
				{"Monitor Alienware 360Hz", "tv", "27 pol QD-OLED", 9800,
					map[string]string{"marca": "Dell", "modelo": "AW2725DF", "ano": "2024", "estado": "novo"}, picsum("aw-monitor")},
				{"Cadeira Secretlab Titan", "audio", "Edição limitada Cyberpunk", 4500,
					map[string]string{"marca": "Secretlab", "estado": "seminovo"}, picsum("secretlab")},
			}},
			{"Moto esportiva", "automoveis", 35000, 75000, []seedItem{
				{"Yamaha MT-09", "moto", "2023, Akrapovic", 62000,
					map[string]string{"ano": "2023", "km": "8000", "cambio": "manual", "combustivel": "gasolina"}, picsum("mt09")},
			}},
			{"Mangás raros", "livros", 800, 3000, []seedItem{
				{"Berserk Deluxe vol 1-10", "manga", "Edição luxo em inglês", 2400,
					map[string]string{"autor": "Kentaro Miura", "editora": "Dark Horse", "ano": "2019", "estado": "seminovo"}, picsum("berserk-deluxe")},
				{"One Piece coleção 1-50", "manga", "Edição brasileira Panini", 1200,
					map[string]string{"autor": "Eiichiro Oda", "editora": "Panini", "ano": "2020", "estado": "usado"}, picsum("op-set")},
			}},
		},
	},
	{
		nome: "Camila Nogueira", email: "demo+camila@local.test", cidade: "Manaus",
		lotes: []seedLote{
			{"Tudo de tênis competitivo", "esportivo", 2500, 5500, []seedItem{
				{"Raquete Wilson Pro Staff", "bola", "RF97 Autograph, com cordagem", 1800,
					map[string]string{"tamanho": "L3", "marca": "Wilson", "estado": "usado"}, picsum("wilson-rf")},
				{"Sapato Asics Solution Speed", "chuteira", "Tamanho 41, novinho", 850,
					map[string]string{"tamanho": "41", "marca": "Asics", "estado": "novo"}, picsum("asics-tenis")},
				{"Saco grande Wilson Tour", "uniforme", "Cabem 9 raquetes", 950,
					map[string]string{"tamanho": "9R", "marca": "Wilson", "estado": "seminovo"}, picsum("bag-wilson")},
				{"Maquina de cordas Stringway", "luva", "Profissional", 2200,
					map[string]string{"tamanho": "univ", "marca": "Stringway", "estado": "usado"}, picsum("stringway")},
			}},
		},
	},
	{
		nome: "Diego Martins", email: "demo+diego@local.test", cidade: "Goiânia",
		lotes: []seedLote{
			{"Marceneiro vendendo", "instrumentos", 5000, 12000, []seedItem{
				{"Serra de bancada Bosch", "estudio", "GTS 254 Professional", 3800, nil, picsum("serra-bosch")},
				{"Compressor 50L Schulz", "estudio", "Compressor pra oficina", 2200, nil, picsum("compressor")},
				{"Lixadeira orbital Makita", "estudio", "Pack 3 lixadeiras", 1600, nil, picsum("makita-lix")},
			}},
			{"Moto + capacetes", "automoveis", 18000, 32000, []seedItem{
				{"Honda Pop 110i 2022", "moto", "Pra começar a pilotar", 9800,
					map[string]string{"ano": "2022", "km": "12000", "cambio": "manual", "combustivel": "flex"}, picsum("pop-110i")},
				{"2 capacetes LS2 + jaqueta", "moto", "Pack pra casal pilotar", 1800,
					map[string]string{"ano": "2023", "estado": "usado"}, picsum("capacete-ls2")},
			}},
		},
	},
	{
		nome: "Patricia Lopes", email: "demo+patricia@local.test", cidade: "Vitória",
		lotes: []seedLote{
			{"Sala completa de cinema", "eletronicos", 15000, 28000, []seedItem{
				{"TV LG OLED C3 65''", "tv", "OLED 4K 120Hz", 11000,
					map[string]string{"marca": "LG", "modelo": "OLED65C3", "ano": "2023", "estado": "seminovo"}, picsum("lg-oled-c3")},
				{"Sistema Dolby Atmos 7.1", "audio", "Denon X3700H + Polk", 8200,
					map[string]string{"marca": "Denon", "ano": "2022", "estado": "seminovo"}, picsum("denon-atmos")},
				{"Projetor 4K Epson", "tv", "Home Cinema 5050UB", 12000,
					map[string]string{"marca": "Epson", "modelo": "5050UB", "ano": "2022", "estado": "usado"}, picsum("epson-proj")},
			}},
		},
	},
	{
		nome: "Eduardo Pinto", email: "demo+eduardo@local.test", cidade: "Belém",
		lotes: []seedLote{
			{"Pacote pesca de luxo", "esportivo", 4000, 9000, []seedItem{
				{"Vara Shimano Stella", "luva", "Stella 4000 + vara", 3800,
					map[string]string{"tamanho": "univ", "marca": "Shimano", "estado": "seminovo"}, picsum("stella-vara")},
				{"Caixa térmica Yeti 65", "uniforme", "Yeti Tundra 65", 3200,
					map[string]string{"tamanho": "65L", "marca": "Yeti", "estado": "usado"}, picsum("yeti")},
				{"Botas de pesca Simms", "chuteira", "G3 tamanho 42", 2200,
					map[string]string{"tamanho": "42", "marca": "Simms", "estado": "usado"}, picsum("simms-boot")},
			}},
		},
	},
	{
		nome: "Mariana Duarte", email: "demo+mariana@local.test", cidade: "Campinas",
		lotes: []seedLote{
			{"Casa comercial", "imoveis", 600000, 1200000, []seedItem{
				{"Sala comercial 80m² centro", "comercial", "Pronta pra escritório", 720000,
					map[string]string{"metragem": "80", "quartos": "0", "vagas": "2", "cidade": "Campinas"}, picsum("sala-com")},
			}},
			{"Notebook gamer + acessórios", "eletronicos", 8000, 15000, []seedItem{
				{"ASUS ROG Strix G16", "notebook", "RTX 4060, i7-13650HX, 32GB", 9800,
					map[string]string{"marca": "Asus", "modelo": "ROG Strix G16", "ano": "2024", "estado": "novo"}, picsum("rog-strix")},
				{"Headset HyperX Cloud III", "audio", "Wireless 7.1", 1200,
					map[string]string{"marca": "HyperX", "estado": "novo"}, picsum("hyperx")},
			}},
		},
	},
	// ===== Personas novas (16-26) =====
	{
		nome: "Felipe Almeida", email: "demo+felipe@local.test", cidade: "Niterói",
		lotes: []seedLote{
			{"Escalada outdoor profissional", "outdoor", 1500, 4500, []seedItem{
				{"Cadeirinha Petzl Sitta", "escalada", "Sitta size M, leve, em ótimo estado", 1800,
					map[string]string{"tamanho": "M", "marca": "Petzl", "estado": "seminovo"}, picsum("petzl-sitta")},
				{"Corda Mammut 9.5 70m", "escalada", "Corda dinâmica simples", 1400,
					map[string]string{"tamanho": "70m", "marca": "Mammut", "estado": "usado"}, picsum("mammut-rope")},
				{"Sapatilha La Sportiva Solution", "chuteira", "39, escalada técnica", 950,
					map[string]string{"tamanho": "39", "marca": "La Sportiva", "estado": "usado"}, picsum("solution")},
			}},
			{"Apto pequeno em Niterói", "imoveis", 280000, 380000, []seedItem{
				{"Studio Icaraí", "apto", "30m² vista pra baía, 1 vaga", 320000,
					map[string]string{"metragem": "30", "quartos": "1", "vagas": "1", "cidade": "Niterói"}, picsum("studio-niteroi")},
			}},
		},
	},
	{
		nome: "Renata Vieira", email: "demo+renata@local.test", cidade: "São Paulo",
		lotes: []seedLote{
			{"Cozinha pro chef", "eletronicos", 5000, 12000, []seedItem{
				{"KitchenAid Artisan 5qt", "audio", "Stand mixer azul, completo", 3800,
					map[string]string{"marca": "KitchenAid", "ano": "2022", "estado": "seminovo"}, picsum("kitchenaid")},
				{"Forno Brastemp combinado", "tv", "Micro + elétrico embutido", 2900,
					map[string]string{"marca": "Brastemp", "ano": "2023", "estado": "seminovo"}, picsum("oven-bras")},
				{"Cafeteira Breville Barista", "audio", "Express com moedor", 4200,
					map[string]string{"marca": "Breville", "ano": "2023", "estado": "novo"}, picsum("breville")},
			}},
			{"Coleção de HQs Marvel", "livros", 600, 2500, []seedItem{
				{"Civil War edição completa", "hq", "Capa dura Panini, ótimo estado", 380,
					map[string]string{"autor": "Mark Millar", "editora": "Panini", "ano": "2018", "estado": "seminovo"}, picsum("civil-war")},
				{"Saga Infinito - 6 livros", "hq", "Encadernados", 720,
					map[string]string{"autor": "Jim Starlin", "editora": "Marvel", "ano": "2018", "estado": "usado"}, picsum("infinito")},
			}},
		},
	},
	{
		nome: "Bruno Carvalho", email: "demo+bruno@local.test", cidade: "São Paulo",
		lotes: []seedLote{
			{"Esportes náuticos", "esportivo", 3000, 9000, []seedItem{
				{"Stand-up paddle inflável", "uniforme", "12'6 racing, com remo carbono", 2800,
					map[string]string{"tamanho": "12'6", "marca": "Red Paddle", "estado": "seminovo"}, picsum("sup-racing")},
				{"Kit kitesurf iniciante", "luva", "Pipa 9m + barra + leash", 4200,
					map[string]string{"tamanho": "9m", "marca": "Cabrinha", "estado": "usado"}, picsum("kite-kit")},
			}},
			{"Mochilas de trilha", "outdoor", 800, 2500, []seedItem{
				{"Osprey Atmos AG 65", "mochila", "Mochila trekking 65L", 1900,
					map[string]string{"tamanho": "65L", "marca": "Osprey", "estado": "seminovo"}, picsum("atmos-65")},
				{"Saco de dormir -5°C", "camping", "Térmico em pluma sintética", 680,
					map[string]string{"tamanho": "M", "marca": "Quechua", "estado": "usado"}, picsum("sleep-bag")},
			}},
		},
	},
	{
		nome: "Larissa Moura", email: "demo+larissa@local.test", cidade: "São Paulo",
		lotes: []seedLote{
			{"Smart home premium", "eletronicos", 6000, 14000, []seedItem{
				{"Apple TV 4K + HomePods", "tv", "2x HomePod mini + Apple TV 128GB", 3400,
					map[string]string{"marca": "Apple", "ano": "2023", "estado": "novo"}, picsum("homekit")},
				{"Aspirador robô Roborock S8", "audio", "Trapeia + aspira", 4800,
					map[string]string{"marca": "Roborock", "modelo": "S8", "ano": "2023", "estado": "novo"}, picsum("roborock")},
				{"Hub Aqara + sensores", "audio", "12 sensores Zigbee + hub", 1400,
					map[string]string{"marca": "Aqara", "estado": "novo"}, picsum("aqara")},
			}},
		},
	},
	{
		nome: "Vinicius Barros", email: "demo+vinicius@local.test", cidade: "Recife",
		lotes: []seedLote{
			{"Carro econômico + scooter", "automoveis", 45000, 80000, []seedItem{
				{"Mobi Like 2023", "hatch", "Hatch básico, baixa km", 58000,
					map[string]string{"ano": "2023", "km": "9000", "cambio": "manual", "combustivel": "flex"}, picsum("mobi-23")},
				{"Scooter elétrica NIU MQi", "moto", "Elétrica urbana, com 2 baterias", 8800,
					map[string]string{"ano": "2024", "km": "1200", "cambio": "automatico", "combustivel": "eletrico"}, picsum("niu")},
			}},
		},
	},
	{
		nome: "Daniela Reis", email: "demo+daniela@local.test", cidade: "Curitiba",
		lotes: []seedLote{
			{"Livros de medicina", "livros", 800, 3000, []seedItem{
				{"Robbins Patologia 10ª ed", "tecnico", "Original em português", 380,
					map[string]string{"autor": "Robbins", "editora": "Elsevier", "ano": "2021", "estado": "seminovo"}, picsum("robbins")},
				{"Harrison Internal Medicine", "tecnico", "Volume único em inglês", 620,
					map[string]string{"autor": "Harrison", "editora": "McGraw", "ano": "2022", "estado": "novo"}, picsum("harrison")},
				{"Kit residência médica - 12 livros", "tecnico", "Bateria pra prova de residência", 980,
					map[string]string{"editora": "Medcel", "ano": "2023", "estado": "usado"}, picsum("medcel-kit")},
			}},
		},
	},
	{
		nome: "Gabriel Santos", email: "demo+gabriel@local.test", cidade: "Florianópolis",
		lotes: []seedLote{
			{"Audio hi-fi", "instrumentos", 8000, 18000, []seedItem{
				{"Amplificador Marantz PM7000N", "audio", "Streaming + amp 60W RMS", 7800, nil, picsum("marantz")},
				{"Caixas Klipsch RP-600M II", "audio", "Par de bookshelves novas", 5200, nil, picsum("klipsch")},
				{"Headphone Sennheiser HD 800S", "audio", "Top de linha aberto", 11000, nil, picsum("hd800s")},
			}},
			{"Casa de campo", "imoveis", 380000, 580000, []seedItem{
				{"Sítio 5000m² em Santo Amaro", "rural", "Casa + lago + pomar", 480000,
					map[string]string{"metragem": "5000", "quartos": "3", "vagas": "4", "cidade": "Florianópolis"}, picsum("sitio-sc")},
			}},
		},
	},
	{
		nome: "Isabela Freitas", email: "demo+isabela@local.test", cidade: "Belo Horizonte",
		lotes: []seedLote{
			{"Câmera + acessórios pro", "eletronicos", 14000, 28000, []seedItem{
				{"Fuji X-T5 + 16-80mm", "camera", "Mirrorless APS-C + lente kit pro", 16500,
					map[string]string{"marca": "Fujifilm", "modelo": "X-T5", "ano": "2023", "estado": "seminovo"}, picsum("xt5")},
				{"Lente Fuji 56mm f/1.2", "camera", "Lente prime retrato", 5800,
					map[string]string{"marca": "Fujifilm", "modelo": "56mm WR", "ano": "2023", "estado": "novo"}, picsum("fuji-56")},
			}},
			{"Bicicleta urbana + acessórios", "esportivo", 1800, 4500, []seedItem{
				{"Bike fixa cromada Pure Cycles", "bola", "Quadro 54, freios mecânicos", 1200,
					map[string]string{"tamanho": "54", "marca": "Pure", "estado": "usado"}, picsum("pure-fixa")},
				{"Mochila messenger Chrome", "luva", "Industries Citizen, 26L", 480,
					map[string]string{"tamanho": "M", "marca": "Chrome", "estado": "usado"}, picsum("chrome-msg")},
			}},
		},
	},
	{
		nome: "Ricardo Gomes", email: "demo+ricardo@local.test", cidade: "Brasília",
		lotes: []seedLote{
			{"Investidor de relógios", "esportivo", 6000, 15000, []seedItem{
				{"Seiko SARB033", "uniforme", "Discontinuado, ótimo estado", 4200,
					map[string]string{"tamanho": "38mm", "marca": "Seiko", "estado": "seminovo"}, picsum("sarb033")},
				{"Hamilton Khaki Field Mech", "uniforme", "Caixa 38mm, mecânico manual", 3800,
					map[string]string{"tamanho": "38mm", "marca": "Hamilton", "estado": "novo"}, picsum("khaki-mech")},
			}},
			{"Coleção HQ vintage", "livros", 1200, 4000, []seedItem{
				{"Watchmen 1ª edição", "hq", "Box DC, em ótimo estado", 480,
					map[string]string{"autor": "Alan Moore", "editora": "DC", "ano": "1987", "estado": "usado"}, picsum("watchmen-1ed")},
				{"Asterix coleção completa francesa", "hq", "40 álbuns Dargaud", 1900,
					map[string]string{"autor": "Goscinny", "editora": "Dargaud", "ano": "1990", "estado": "usado"}, picsum("asterix")},
			}},
		},
	},
	{
		nome: "Aline Ferraz", email: "demo+aline@local.test", cidade: "Porto Alegre",
		lotes: []seedLote{
			{"Mãe vendendo brinquedos pesados", "esportivo", 800, 2500, []seedItem{
				{"Balanço de jardim Fisher Price", "luva", "Para criança 2-6 anos, ótima estrutura", 580,
					map[string]string{"tamanho": "G", "marca": "Fisher Price", "estado": "usado"}, picsum("fp-jardim")},
				{"Triciclo Smoby Be Fun", "bola", "Cor azul, com pedais e haste guia", 380,
					map[string]string{"tamanho": "P", "marca": "Smoby", "estado": "usado"}, picsum("smoby-tri")},
				{"Cama elástica 3m", "uniforme", "Pula-pula com proteção", 950,
					map[string]string{"tamanho": "3m", "marca": "Acrobata", "estado": "usado"}, picsum("trampolim")},
			}},
		},
	},
	{
		nome: "Marcelo Pires", email: "demo+marcelo@local.test", cidade: "Rio de Janeiro",
		lotes: []seedLote{
			{"Garagem do colecionador", "automoveis", 80000, 200000, []seedItem{
				{"Fusca 1972 restaurado", "hatch", "Cor original, motor e lataria recuperados", 78000,
					map[string]string{"ano": "1972", "km": "12000", "cambio": "manual", "combustivel": "gasolina"}, picsum("fusca-72")},
				{"Opala SS 1979", "sedan", "Documentação ok, peça de coleção", 85000,
					map[string]string{"ano": "1979", "km": "98000", "cambio": "manual", "combustivel": "gasolina"}, picsum("opala")},
			}},
		},
	},
	{
		nome: "Sofia Andrade", email: "demo+sofia@local.test", cidade: "Salvador",
		lotes: []seedLote{
			{"Outdoor pesado de viagem", "outdoor", 2500, 6000, []seedItem{
				{"Barraca MSR Hubba Hubba 2P", "barraca", "Backpacking, ultraleve", 2800,
					map[string]string{"tamanho": "2P", "marca": "MSR", "estado": "seminovo"}, picsum("hubba")},
				{"Fogareiro JetBoil Flash", "camping", "Combo + canister", 750,
					map[string]string{"marca": "JetBoil", "estado": "seminovo"}, picsum("jetboil")},
				{"Filtro de água Sawyer Squeeze", "camping", "Filtro pessoal de trilha", 280,
					map[string]string{"marca": "Sawyer", "estado": "novo"}, picsum("sawyer")},
				{"Mochila Deuter Aircontact 60+10", "mochila", "Trekking pesado", 1800,
					map[string]string{"tamanho": "70L", "marca": "Deuter", "estado": "usado"}, picsum("deuter")},
			}},
		},
	},
}

var meusSeed = []seedLote{
	{"Carro + Moto", "automoveis", 80000, 150000, []seedItem{
		{"Civic 2019 EXL", "sedan", "Sedan automático, 60mil km, único dono", 95000,
			map[string]string{"ano": "2019", "km": "60000", "cambio": "automatico", "combustivel": "flex"}, picsum("civic19")},
		{"CB 500F", "moto", "Moto naked 2020, revisões em dia", 28000,
			map[string]string{"ano": "2020", "km": "12000", "cambio": "manual", "combustivel": "gasolina"}, picsum("cb500f")},
	}},
	{"Estúdio Caseiro", "instrumentos", 5000, 12000, []seedItem{
		{"Stratocaster MX", "guitarra", "Fender Mexicana, escala maple", 4500, nil, picsum("strat-mx")},
		{"Yamaha P-125", "piano", "Piano digital 88 teclas pesadas", 4200, nil, picsum("yamaha-p125")},
		{"Kit microfones SM58", "estudio", "3x SM58 + cabos + pedestais", 1800, nil, picsum("sm58-kit")},
	}},
	{"Setup Gamer Completo", "eletronicos", 10000, 25000, []seedItem{
		{"PS5 Slim 1TB", "console", "Lacrado, 2 controles", 4200,
			map[string]string{"marca": "Sony", "modelo": "Slim", "ano": "2024", "estado": "novo"}, picsum("ps5-slim")},
		{"MacBook Pro M2", "notebook", "14 pol, 16GB RAM, 512 SSD", 12000,
			map[string]string{"marca": "Apple", "modelo": "MBP M2", "ano": "2023", "estado": "seminovo"}, picsum("mbp-m2")},
		{"Sony A7 IV", "camera", "Mirrorless full-frame + lente 28-70mm", 18000,
			map[string]string{"marca": "Sony", "modelo": "A7 IV", "ano": "2022", "estado": "seminovo"}, picsum("sony-a7iv")},
	}},
	{"Kit Futebol Pro", "esportivo", 200, 600, []seedItem{
		{"Chuteira Predator Mania", "chuteira", "Tamanho 41, pouco uso", 280,
			map[string]string{"tamanho": "41", "marca": "Adidas", "estado": "usado"}, picsum("predator")},
		{"Bola Brazuca FIFA", "bola", "Bola oficial, ótimo estado", 180,
			map[string]string{"tamanho": "5", "marca": "Adidas", "estado": "usado"}, picsum("brazuca")},
		{"Luva goleiro Reusch", "luva", "Luva profissional", 140,
			map[string]string{"tamanho": "9", "marca": "Reusch", "estado": "novo"}, picsum("reusch")},
	}},
	{"Biblioteca pessoal", "livros", 300, 1200, []seedItem{
		{"Senhor dos Anéis edição luxo", "literatura", "Trilogia + Hobbit, capa dura HarperCollins", 580,
			map[string]string{"autor": "Tolkien", "editora": "HarperCollins", "ano": "2020", "estado": "novo"}, picsum("lotr-lux")},
		{"Os Pilares da Terra", "literatura", "Capa dura Arqueiro", 120,
			map[string]string{"autor": "Ken Follett", "editora": "Arqueiro", "ano": "2018", "estado": "seminovo"}, picsum("pilares")},
	}},
}

// Avaliações pré-existentes — alimentam reputação inicial via trigger.
var seedAvaliacoes = []struct {
	De, Para string
	Nota     int
	Coment   string
}{
	{"demo+maria@local.test", "demo+pedro@local.test", 5, "Tranquilo, item exatamente como descrito."},
	{"demo+pedro@local.test", "demo+maria@local.test", 5, "Negócio rápido, recomendo."},
	{"demo+ana@local.test", "demo+rafael@local.test", 4, "Tudo certo, encontro foi um pouco corrido."},
	{"demo+rafael@local.test", "demo+ana@local.test", 5, "Fluxo perfeito, muito profissional."},
	{"demo+carlos@local.test", "demo+thiago@local.test", 5, "Setup veio impecável, embalagem ótima."},
	{"demo+thiago@local.test", "demo+carlos@local.test", 4, "Tudo certo, só demorou um pouco pra confirmar."},
	{"demo+beatriz@local.test", "demo+juliana@local.test", 5, "Comunicação 10."},
	{"demo+juliana@local.test", "demo+beatriz@local.test", 5, "Excelente."},
	{"demo+lucas@local.test", "demo+fernanda@local.test", 4, "Bom, faltou só uns ajustes finos."},
	{"demo+fernanda@local.test", "demo+lucas@local.test", 5, "Top, recomendo demais."},
	{"demo+diego@local.test", "demo+camila@local.test", 5, "Item como novo, perfeito."},
	{"demo+camila@local.test", "demo+diego@local.test", 5, "Negociação fluiu super bem."},
	{"demo+patricia@local.test", "demo+eduardo@local.test", 5, "Pegou o que combinamos, sem stress."},
	{"demo+eduardo@local.test", "demo+patricia@local.test", 4, "Tudo certo. Boa parceria."},
	{"demo+mariana@local.test", "demo+maria@local.test", 5, "Confiável."},
	// Novos
	{"demo+felipe@local.test", "demo+sofia@local.test", 5, "Equipamento outdoor em estado impecável."},
	{"demo+sofia@local.test", "demo+felipe@local.test", 5, "Pessoa de confiança, troca rápida."},
	{"demo+renata@local.test", "demo+larissa@local.test", 4, "Cozinha foi top, smart home tive trabalho de configurar."},
	{"demo+larissa@local.test", "demo+renata@local.test", 5, "Cozinha veio com tudo, super recomendo."},
	{"demo+bruno@local.test", "demo+gabriel@local.test", 5, "Audio premium veio impecável."},
	{"demo+gabriel@local.test", "demo+bruno@local.test", 4, "Outdoor um pouco usado mas funcional."},
	{"demo+isabela@local.test", "demo+pedro@local.test", 5, "Câmera nas condições prometidas."},
	{"demo+pedro@local.test", "demo+isabela@local.test", 5, "Vendedora super atenciosa."},
	{"demo+ricardo@local.test", "demo+marcelo@local.test", 5, "Carro de coleção como descrito, documentação perfeita."},
	{"demo+marcelo@local.test", "demo+ricardo@local.test", 5, "Relógios autênticos, garantia honrada."},
	{"demo+vinicius@local.test", "demo+aline@local.test", 5, "Brinquedos em ótimo estado, criança feliz."},
	{"demo+aline@local.test", "demo+vinicius@local.test", 4, "Mobi novinho, scooter precisou de pequena revisão."},
	{"demo+daniela@local.test", "demo+isabela@local.test", 5, "Câmera ótima, ela é super tranquila."},
	{"demo+camila@local.test", "demo+ricardo@local.test", 5, "Relógio Seiko impecável."},
	{"demo+thiago@local.test", "demo+ricardo@local.test", 5, "Coleção de HQs em estado de coleção mesmo."},
	{"demo+rafael@local.test", "demo+gabriel@local.test", 5, "Audio hi-fi entregue com todos os cabos."},
}

// Negociações pré-existentes pra a aba Negócios já abrir cheia.
var seedNegociacoes = []struct {
	LoteAOwnerEmail, LoteAFiltroTitulo string
	LoteBOwnerEmail, LoteBFiltroTitulo string
	Status                             string
	AmbosAceitaram                     bool
}{
	{"demo+maria@local.test", "Carro popular completo",
		"demo+carlos@local.test", "Carro família",
		"contraproposta", false},
	{"demo+rafael@local.test", "Studio musical do gaúcho",
		"demo+ana@local.test", "Pacote estúdio + DJ",
		"proposta", false},
	{"demo+thiago@local.test", "Setup gamer pesado",
		"demo+patricia@local.test", "Sala completa de cinema",
		"contraproposta", false},
	{"demo+felipe@local.test", "Escalada outdoor profissional",
		"demo+sofia@local.test", "Outdoor pesado de viagem",
		"contraproposta", false},
	{"demo+bruno@local.test", "Mochilas de trilha",
		"demo+beatriz@local.test", "Camping de praia",
		"proposta", false},
	{"demo+isabela@local.test", "Câmera + acessórios pro",
		"demo+pedro@local.test", "Kit fotógrafo iniciante",
		"contraproposta", false},
	{"demo+marcelo@local.test", "Garagem do colecionador",
		"demo+thiago@local.test", "Moto esportiva",
		"proposta", false},
	{"demo+ricardo@local.test", "Coleção HQ vintage",
		"demo+thiago@local.test", "Mangás raros",
		"contraproposta", false},
}
