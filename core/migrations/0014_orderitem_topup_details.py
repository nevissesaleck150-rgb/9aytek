from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0013_digitalservice_image'),
    ]

    operations = [
        migrations.AddField(
            model_name='orderitem',
            name='topup_account_id',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
        migrations.AddField(
            model_name='orderitem',
            name='topup_payer',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
        migrations.AddField(
            model_name='orderitem',
            name='topup_recharge_type',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
    ]
