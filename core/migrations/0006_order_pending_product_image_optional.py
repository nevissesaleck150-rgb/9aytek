from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0005_user_is_approved'),
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
                    ('delivered', 'Delivered'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='product',
            name='image',
            field=models.ImageField(blank=True, null=True, upload_to='products/'),
        ),
    ]
