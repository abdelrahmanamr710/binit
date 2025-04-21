class UserModel {
  String? uid;
  String? email;
  String? name;
  String? userType;
  String? phone; // Add phone number
  String? taxId; // Add tax ID
  // Add other user-related fields as necessary

  UserModel({this.uid, this.email, this.name, this.userType, this.phone, this.taxId}); // Update constructor

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    name = json['name'];
    userType = json['userType'];
    phone = json['phone']; // Parse phone number
    taxId = json['taxId']; // Parse tax ID
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['email'] = email;
    data['name'] = name;
    data['userType'] = userType;
    data['phone'] = phone; // Serialize phone number
    data['taxId'] = taxId; // Serialize tax ID
    return data;
  }
}

