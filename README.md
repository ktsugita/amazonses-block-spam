# amazonses-block-spam
This is a Lambda function that discards emails received by AmazonSES if they are spam

AmazonSESで受信したメールについて、保存不要と判断したメールを破棄するためのLambda関数です。
受信したメールのReceiptにある評価結果を見て、保存不要と判断したらCONTINUE，そうでない場合はSTOP_RULEを返します。後続のRULEで「STOP_RULE_SET」を実施することで破棄します。記録等を残したい場合、その前に適宜アクションを追加してください。VirusVerdict, SpamVerdict, DMARCVerdictのどれかが"FAIL"の場合にCONTINUEを返します。

STOP_RULE_SETする前に、プレフィクスを分けてS3保存する等の用途が考えられます。ただし、バウンス応答はしないで破棄することをお勧めします。AmazonSESの受信ルールセットの実行は、すでに受信が済んだ後なので、受け取り自体は拒否できません。バウンス応答すると、バックスキャッター攻撃を仲介してしまう可能性があります。

## 使い方

このリポジトリをクローンして`cd`します。
`setup.sh`の2行を適宜編集します。特に問題なければ`lambda_name`はそのままでよいと思います。

```bash
lambda_name=amazonses-block-spam
region=us-west-2
```

必要な権限をもったユーザをawscliのデフォルトプロファイルに設定して、`setup.sh`を実行します。
正常に完了すると、指定のリージョンに指定のlambda_nameのLambda関数が作成されます。
Lambda関数の他に、Lambda関数をデプロイするためのECRや実行ロール等も作成されます。
作成されない場合は、デフォルトプロファイルが正しくないか、権限が足りていないと思われます。

作成された関数のテストを開き、「新しいイベントを作成」、イベント名「ses」、テンプレートは「SES Email Receiving」を指定して保存して、テストを実行します。実行結果が「{"disposition": "STOP_RULE"}」になって成功していることを確認します。Cloudwatch logsにもログが出ていることを確認してください。

SESの「Eメール受信」を開き、ルールセットの最初のルールとして下記の要領で設定します。
ルール名「block-spam」
スパムとウイルススキャン: 有効化
受信者の条件: すべてのメールに適用したい場合は指定不要
新しいアクションの追加: AWS Lambda関数の呼び出し
Lambda関数: 指定したLambda関数(amazonses-block-spam)
呼び出しタイプ: RequestResponse の呼び出し
新しいアクションの追加: ルールセットの停止

以上の設定により、受信不要と判断されなかったメールは次のルールに進みます。受信不要と判断されたメールは、このルールのルールセットの停止で破棄されます。次のルール等でS3保存等のアクションを追加してください。
