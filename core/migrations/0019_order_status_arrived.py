# Generated manually to add the delivery-arrived status.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0018_user_bank_account_user_driving_license_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='order',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending Payment'),
                    ('paid', 'Paid'),
                    ('ready', 'Ready for Pick'),
                    ('on_way', 'On the Way'),
                    ('arrived', 'Arrived to Customer'),
                    ('delivered', 'Delivered'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
    ]
