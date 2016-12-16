# -*- coding: utf-8 -*-
# Generated by Django 1.9.4 on 2016-03-08 00:13
from __future__ import unicode_literals

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='rightscale_account',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('account_id', models.IntegerField()),
                ('refresh_token', models.CharField(max_length=40)),
                ('name', models.CharField(max_length=255)),
                ('cm_uri', models.CharField(max_length=255)),
                ('ss_uri', models.CharField(max_length=255)),
            ],
        ),
        migrations.CreateModel(
            name='terminate_resource',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rs_type', models.CharField(max_length=255)),
                ('action', models.CharField(max_length=64)),
                ('age', models.PositiveIntegerField()),
                ('tags', models.TextField()),
                ('json', models.TextField()),
            ],
        ),
        migrations.CreateModel(
            name='terminate_session',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('skynet_start_time', models.DateTimeField()),
                ('cat_start_time', models.DateTimeField(blank=True, null=True)),
                ('cat_version_requested', models.CharField(max_length=16)),
                ('cat_version_reported', models.CharField(blank=True, max_length=16, null=True)),
                ('cat_end_time', models.DateTimeField(blank=True, null=True)),
                ('cloud_app_href', models.CharField(blank=True, max_length=255, null=True)),
                ('auth_user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
                ('rightscale_account', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='www.rightscale_account')),
            ],
        ),
        migrations.AddField(
            model_name='terminate_resource',
            name='session',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='www.terminate_session'),
        ),
    ]
