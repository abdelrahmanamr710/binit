class UserModel {
  String? uid;
  String? email;
  String? name;
  String? userType;
  // Add other user-related fields as necessary

  UserModel({this.uid, this.email, this.name, this.userType});

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    name = json['name'];
    userType = json['userType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['email'] = email;
    data['name'] = name;
    data['userType'] = userType;
    return data;
  }
}
