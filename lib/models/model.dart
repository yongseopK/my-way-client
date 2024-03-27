class Login {
  final String loginEmail;
  final String loginName;
  final String loginToken;

  Login(this.loginEmail, this.loginName, this.loginToken);

  Login.fromJson(Map<String, dynamic> json)
      : loginEmail = json['loginEmail'],
        loginName = json['loginName'],
        loginToken = json['loginToken'];

  Map<String, dynamic> toJSon() => {
        'loginEmail': loginEmail,
        'loginName': loginName,
        'loginToken': loginToken,
      };
}
