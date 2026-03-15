"""
Django signals for the Core app.
Automatically creates UserProfile when a new User is created.
"""

from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import UserProfile


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """
    Automatically create a UserProfile when a new User is created.

    Args:
        sender: The model class that sent the signal (User)
        instance: The actual User instance being saved
        created: Boolean indicating if a new record was created
        **kwargs: Additional keyword arguments
    """
    if created:
        UserProfile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """
    Save the UserProfile when the User is saved.

    Args:
        sender: The model class that sent the signal (User)
        instance: The actual User instance being saved
        **kwargs: Additional keyword arguments
    """
    try:
        instance.userprofile.save()
    except UserProfile.DoesNotExist:
        # If the profile doesn't exist (e.g., for existing users), create it
        UserProfile.objects.create(user=instance)
