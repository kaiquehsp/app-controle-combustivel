# ⛽ Controle de Combustível

Aplicativo Flutter para registrar os abastecimentos de um veículo e acompanhar os **gastos com combustível** e o **consumo** ao longo do tempo.

---

## 📱 Funcionalidades

### 1. Cadastro do veículo

- Apenas **um veículo por vez**, com **marca, modelo, ano e cilindrada** do motor (cm³).
- Tipo de veículo: carro, moto ou caminhão.
- **Marcas e modelos são consultados na BrasilAPI (tabela FIPE)**. A lista de modelos depende da marca escolhida e as duas telas de seleção têm busca.
- Para cadastrar outro veículo, é preciso **excluir o atual**. A exclusão pede confirmação e remove também **todos os abastecimentos associados**.

### 2. Registro de abastecimentos

- Tipo de combustível: **etanol, gasolina ou diesel**.
- **Preço por litro** (R$), **quilometragem** no momento do abastecimento, **litros** abastecidos e **data e horário**.
- O **valor total** é calculado automaticamente (`preço por litro × litros`) e aparece em tempo real no formulário.
- Os abastecimentos podem ser editados ou excluídos.
- Validação: a quilometragem precisa ser maior que a do abastecimento anterior e menor que a do posterior, de acordo com a data e a hora.

### 3. Persistência local

- O veículo e os abastecimentos ficam salvos no dispositivo com **shared_preferences**, em formato JSON, e continuam disponíveis depois que o app é fechado e aberto de novo.

### 4. Dashboard e gráficos

Considerando que todos os abastecimentos completam o tanque:

| Indicador              | Cálculo                                   |
| ---------------------- | ----------------------------------------- |
| Valor do abastecimento | preço por litro × litros                  |
| Distância percorrida   | km atual − km do abastecimento anterior   |
| Consumo (km/L)         | distância ÷ litros do abastecimento atual |
| Custo (R$/km)          | valor do abastecimento atual ÷ distância  |

- O **1º abastecimento** é só a referência inicial, por isso não tem km/L nem R$/km.
- Cartões de resumo: total gasto, número de abastecimentos e litros, consumo médio e custo médio. As médias são ponderadas pela distância.
- Gráficos feitos com **fl_chart**:
  - 📊 barras com o **valor de cada abastecimento**;
  - 📈 linha com a **evolução do consumo (km/L)**;
  - 📈 linha com a **evolução do custo por km (R$/km)**.
- Tabela com os indicadores de cada abastecimento.

---

## 🖼️ Capturas de tela

|                  Tela inicial                   |                       Cadastro do veículo                        |                Seleção de marca (BrasilAPI)                |
| :---------------------------------------------: | :--------------------------------------------------------------: | :--------------------------------------------------------: |
| ![Tela inicial](docs/screenshots/01_inicio.png) | ![Cadastro do veículo](docs/screenshots/02_cadastro_veiculo.png) | ![Seleção de marca](docs/screenshots/03_selecao_marca.png) |

|                Seleção de modelo (BrasilAPI)                 |             Veículo cadastrado              |                        Novo abastecimento                         |
| :----------------------------------------------------------: | :-----------------------------------------: | :---------------------------------------------------------------: |
| ![Seleção de modelo](docs/screenshots/04_selecao_modelo.png) | ![Veículo](docs/screenshots/05_veiculo.png) | ![Novo abastecimento](docs/screenshots/06_novo_abastecimento.png) |

|                  Lista de abastecimentos                  |            Dashboard (resumo e valores)             |              Dashboard (km/L e R$/km)               |
| :-------------------------------------------------------: | :-------------------------------------------------: | :-------------------------------------------------: |
| ![Abastecimentos](docs/screenshots/07_abastecimentos.png) | ![Dashboard 1](docs/screenshots/08_dashboard_1.png) | ![Dashboard 2](docs/screenshots/09_dashboard_2.png) |

|                     Confirmação de exclusão                     |
| :-------------------------------------------------------------: |
| ![Exclusão do veículo](docs/screenshots/10_excluir_veiculo.png) |

---

## 🌐 API utilizada

**[BrasilAPI](https://brasilapi.com.br/docs) – Tabela FIPE**, pública e sem autenticação.

| Uso                     | Endpoint                                                                        |
| ----------------------- | ------------------------------------------------------------------------------- |
| Listar marcas           | `GET https://brasilapi.com.br/api/fipe/marcas/v1/{tipoVeiculo}`                 |
| Listar modelos da marca | `GET https://brasilapi.com.br/api/fipe/veiculos/v1/{tipoVeiculo}/{codigoMarca}` |

`tipoVeiculo` pode ser `carros`, `motos` ou `caminhoes`.

## 📦 Bibliotecas

| Pacote                                                              | Uso                             |
| ------------------------------------------------------------------- | ------------------------------- |
| [`http`](https://pub.dev/packages/http)                             | Requisições à BrasilAPI         |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Persistência local dos dados    |
| [`fl_chart`](https://pub.dev/packages/fl_chart)                     | Gráficos do dashboard           |
| [`intl`](https://pub.dev/packages/intl) + `flutter_localizations`   | Moeda, números e datas em pt-BR |

---

## ▶️ Como executar

**Pré-requisitos:** [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.27 ou superior, além de um emulador Android, um dispositivo físico ou o Chrome.

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd controle_combustivel

# 2. Instalar as dependências
flutter pub get

# 3. Executar (escolha o dispositivo)
flutter devices
flutter run                 # emulador/dispositivo conectado
flutter run -d chrome       # navegador
```

Testes unitários e de widget:

```bash
flutter test
```

---

## 🗂️ Estrutura do projeto

```
lib/
├── main.dart                         # Inicialização, tema e localização pt-BR
├── models/
│   ├── veiculo.dart                  # Veículo + tipos (carros/motos/caminhões)
│   ├── abastecimento.dart            # Abastecimento + tipos de combustível
│   └── opcao_fipe.dart               # Item de marca/modelo da FIPE
├── services/
│   ├── fipe_service.dart             # Consumo da BrasilAPI
│   └── storage_service.dart          # Persistência local (shared_preferences)
├── state/
│   └── app_state.dart                # Estado global (ChangeNotifier)
├── screens/
│   ├── home_screen.dart              # Navegação principal (NavigationBar)
│   ├── veiculo_form_screen.dart      # Cadastro do veículo
│   ├── selecao_opcao_screen.dart     # Seleção com busca (marca/modelo)
│   ├── veiculo_tab.dart              # Dados e exclusão do veículo
│   ├── abastecimento_form_screen.dart# Registro/edição de abastecimento
│   ├── abastecimentos_tab.dart       # Lista de abastecimentos
│   └── dashboard_tab.dart            # Indicadores e gráficos
├── utils/
│   ├── indicadores.dart              # Cálculo de km/L, R$/km e resumo
│   └── formatadores.dart             # Formatação pt-BR e leitura de decimais
└── widgets/
    └── graficos.dart                 # Gráficos de barra e linha (fl_chart)
test/
├── indicadores_test.dart             # Testes dos cálculos
└── widget_test.dart                  # Teste da tela inicial
```
