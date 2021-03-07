# Windows Virtual Desktop Reference Architecture

本番を想定したWindows Virtual Desktopのリファレンスアーキテクチャ

Preview機能などを積極的に取り入れているため、実際の本番環境で使うには十分注意が必要です。WVD環境を自社で構築、運用していたり、SIでWVD環境構築を担い今後のアーキテクチャ参考を求めている方に向けて公開しています。

ここで紹介するアーキテクチャは一例にすぎませんが、典型的なアーキテクチャであり、考慮するべきポイントを実例をもとに考えることができます。

# リファレンスアーキテクチャ (全体像)
![リファレンスアーキテクチャ](images/wvd-ra.png)

## 特徴
- ネットワークはハブ & スポーク アーキテクチャ
- インターネットに直接VMを公開しない; 管理、緊急時にはBastionを利用
- インターネットアクセスはオンプレミスに引き込まず、Azure上でブレークアウトさせる; Azure Firewall Premiumを使って柔軟で詳細なアクセスコントロール
- 高可用性を考慮; Availability Zone、Availability Set、マネージドサービスを利用
- ログの集中管理; Azure Monitorブックで可視化

ここから、段階的に環境を構築します。

# リファレンスアーキテクチャ (ネットワークインフラ)
![ネットワーク](images/wvd-ra-network.png)

下記からデプロイすると、上記のシステムが作成されます。

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2ftakeokams%2fwvd-reference-architecture%2fmain%2fazuredeploy.json)

補足
- 次のAD作成を行う場合は、Availability Zoneが必須となるので、東日本リージョンなどにデプロイしてください。西日本リージョンは対応していません
- Azure Firewall Premiumには、TLS Inspectionのための自己署名証明書のセット、WVDで必要とされるルールやログ取得の設定がされますが、他のインターネット向けのアクセスは許可されません
- VPN Gatewayの作成はオプションです。ExpressRouteで接続する場合はfalseのままにして、オンプレミスと接続します
- VM数に1をセットすると、Windows 10 Pro 20H2を1台、Spoke Networkに作るので、テスト用に使えます。例えばAzure Firewallのルール、オンプレミス環境との疎通など
- つまり、この環境だけでも、WVDでなく、Bastion経由のVM環境であればほどほど使えます

# リファレンスアーキテクチャ (Active Directory)
![Active Directory](images/wvd-ra-ra.png)

下記からデプロイすると、既存環境に対してActive Directoryのドメインコントローラがデプロイされます。

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2ftakeokams%2fwvd-reference-architecture%2fmain%2faddeploy.json)

補足
- ハブネットワークにデプロイします。通常、上でデフォルト値で作ったVNetに対してデプロイする場合は、ネットワークの値を変更する必要はありません
- Availability Zoneを前提としていますので、対応している東日本リージョンなどにデプロイしてください。また、上記で作成したVNetと同じリージョンである必要があります
- ドメイン名はAzure Active Directoryと同じものが望ましいですが、必須ではありません
- 2つのWindows Server VM、PDCとBDC、PDCに対してはAD Certificate ServicesのEnterprise Root CAがこのデプロイで構成されます
- PDCにはAzure AD Connectがインストールされています。Azure Active Directoryと今ここで作ったADDCを同期するため、管理者でログインし、デスクトップ上にあるAzure AD Connectのアイコンをダブルクリックしてウィザードに従い構成する必要があります
- 名前解決を統一して行うため、デプロイが終わればハブネットワークのVNetにはPDC,BDCをカスタムDNSとしてセットし、ファイアウォールポリシーでDNSプロキシを構成します。さらに、スポークネットワークのVNetのDNSには、Azure Firewall Premiumのプライベートアドレスをセットします
- Azure Firewall PremiumのTLS Inspectionで使う証明書に、Active Directory Certificate Servicesで作成したEnterprise Root CAで署名した、Intermediate CAをセットします。既存であるKey Vaultに自分に対してアクセス権限を付与し、統合されていないCAによって発行された証明書を作成してCSRを出力し、Enterprise Root CAで署名してからKey Vaultに取り込んで、ファイアウォールポリシーのTLS Inspectionで証明書を付け替えます
- オンプレミスでActive Directoryを運用していて、同じアイデンティティを使いたい場合は、オンプレミスとつなげる必要があるのでこのテンプレートは使わず独自に構成する必要があります
- マネージドサービスであるAzure Active Directory Domain Servicesを使うこともできますが、Active Directory Certificate Servicesがないため、Azure Firewall PremiumのTLS Inspectionで使う証明書は独自に手配する必要があり、また各仮想デスクトップイメージに対しても配布方法を考慮する必要があります

# ここから
これで、WVDをデプロイする環境が整いました。

ホストプール等関連リソースを作成し、ログ関連の設定をして、利用者を割り当てれば、WVDとして最低限の利用環境が整い、使うことができます。

実際には、日本語イメージの準備、ファイアウォール許可ルールの設定、FSLogixを使ったプロファイル環境の構築、各種利用ポリシーの設定などを行う必要があるでしょう。


# 参考
- [Azure Reference: Hub-spoke network topology in Azure](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)

- [Quick Start Template: Create a new AD Domain with 2 DCs using Availability Zones](https://azure.microsoft.com/ja-jp/resources/templates/active-directory-new-domain-ha-2-dc-zones/)

