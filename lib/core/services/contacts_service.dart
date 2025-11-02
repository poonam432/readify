import 'package:contacts_service/contacts_service.dart' as cs;
import 'package:permission_handler/permission_handler.dart';

class AppContact {
  final String displayName;
  final String? phoneNumber;
  final String? email;

  AppContact({
    required this.displayName,
    this.phoneNumber,
    this.email,
  });
}

class ContactsService {
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  Future<List<AppContact>> getContacts() async {
    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      return [];
    }

    try {
      final contacts = await cs.ContactsService.getContacts(
        withThumbnails: false,
      );

      return contacts.map((contact) {
        String? phoneNumber;
        String? email;

        if (contact.phones != null && contact.phones!.isNotEmpty) {
          phoneNumber = contact.phones!.first.value;
        }

        if (contact.emails != null && contact.emails!.isNotEmpty) {
          email = contact.emails!.first.value;
        }

        return AppContact(
          displayName: contact.displayName ?? 'Unknown',
          phoneNumber: phoneNumber,
          email: email,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AppContact?> getCurrentUserProfile() async {
    try {
      final contacts = await cs.ContactsService.getContacts(
        withThumbnails: false,
      );

      // Try to find "Me" contact or first contact marked as me
      for (var contact in contacts) {
        if (contact.displayName?.toLowerCase().contains('me') == true ||
            contact.givenName?.toLowerCase() == 'me') {
          String? phoneNumber;
          String? email;

          if (contact.phones != null && contact.phones!.isNotEmpty) {
            phoneNumber = contact.phones!.first.value;
          }

          if (contact.emails != null && contact.emails!.isNotEmpty) {
            email = contact.emails!.first.value;
          }

          return AppContact(
            displayName: contact.displayName ?? 'My Profile',
            phoneNumber: phoneNumber,
            email: email,
          );
        }
      }

      // If no "Me" contact found, return null or create a default
      return null;
    } catch (e) {
      return null;
    }
  }
}

